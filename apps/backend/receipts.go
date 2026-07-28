package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
)

func (q *DBQueries) UpsertReceiptDetail(ctx context.Context, expenseID string, req CreateReceiptRequest, createdBy string) (*ReceiptDetail, error) {
	var ocrPaise *int64
	if req.OCRTotal != nil {
		p := int64(*req.OCRTotal * 100)
		ocrPaise = &p
	}

	rd := &ReceiptDetail{
		ExpenseID: expenseID,
		Merchant:  req.Merchant,
		OCRTotal:  ocrPaise,
		OCRDate:   req.OCRDate,
		LineItems: req.LineItems,
		CreatedBy: createdBy,
		CreatedAt: time.Now(),
	}

	_, err := q.pool.Exec(ctx,
		`INSERT INTO public.receipt_details (expense_id, merchant, ocr_total, ocr_date, line_items, created_by, created_at)
		 VALUES ($1, $2, $3, $4, $5, $6, $7)
		 ON CONFLICT (expense_id)
		 DO UPDATE SET merchant = EXCLUDED.merchant,
		               ocr_total = EXCLUDED.ocr_total,
		               ocr_date = EXCLUDED.ocr_date,
		               line_items = EXCLUDED.line_items,
		               created_by = EXCLUDED.created_by`,
		expenseID, req.Merchant, ocrPaise, req.OCRDate, req.LineItems, createdBy, time.Now(),
	)
	if err != nil {
		return nil, fmt.Errorf("upsert receipt detail: %w", err)
	}

	return rd, nil
}

func (q *DBQueries) GetReceiptDetail(ctx context.Context, expenseID string) (*ReceiptDetail, error) {
	row := q.pool.QueryRow(ctx,
		`SELECT expense_id, merchant, ocr_total, ocr_date, line_items, created_by, created_at
		 FROM public.receipt_details WHERE expense_id = $1`, expenseID)

	var rd ReceiptDetail
	err := row.Scan(&rd.ExpenseID, &rd.Merchant, &rd.OCRTotal, &rd.OCRDate, &rd.LineItems, &rd.CreatedBy, &rd.CreatedAt)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("get receipt detail: %w", err)
	}
	return &rd, nil
}

func createReceiptHandler(q *DBQueries) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		expenseID := chi.URLParam(r, "expenseID")
		if expenseID == "" {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "expenseID is required"})
			return
		}

		var req CreateReceiptRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "invalid request body"})
			return
		}

		createdBy := participantIDFromCtx(r.Context())
		if createdBy == "" {
			writeJSON(w, http.StatusUnauthorized, ErrorResponse{Error: "unauthorized"})
			return
		}

		expense, err := q.GetExpense(r.Context(), expenseID)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
			return
		}
		if expense == nil {
			writeJSON(w, http.StatusNotFound, ErrorResponse{Error: "expense not found"})
			return
		}
		if expense.PayerID != createdBy {
			writeJSON(w, http.StatusForbidden, ErrorResponse{Error: "only the payer of the expense can attach or update receipts"})
			return
		}

		rd, err := q.UpsertReceiptDetail(r.Context(), expenseID, req, createdBy)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
			return
		}

		writeJSON(w, http.StatusOK, rd)
	}
}

func getReceiptHandler(q *DBQueries) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		expenseID := chi.URLParam(r, "expenseID")
		if expenseID == "" {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "expenseID is required"})
			return
		}

		callerPID := participantIDFromCtx(r.Context())
		if callerPID == "" {
			writeJSON(w, http.StatusUnauthorized, ErrorResponse{Error: "unauthorized"})
			return
		}

		expense, err := q.GetExpense(r.Context(), expenseID)
		if err != nil || expense == nil {
			writeJSON(w, http.StatusNotFound, ErrorResponse{Error: "expense not found"})
			return
		}

		// Authorization check: Verify caller is payer, split member, or group member
		isAuthorized := expense.PayerID == callerPID
		if !isAuthorized {
			for _, sp := range expense.Splits {
				if sp.ParticipantID == callerPID {
					isAuthorized = true
					break
				}
			}
		}
		if !isAuthorized && expense.ListID != nil && *expense.ListID != "" {
			inGroup, err := q.IsUserInGroup(r.Context(), *expense.ListID, callerPID)
			if err == nil && inGroup {
				isAuthorized = true
			}
		}

		if !isAuthorized {
			writeJSON(w, http.StatusForbidden, ErrorResponse{Error: "access denied: not authorized to view receipt"})
			return
		}

		rd, err := q.GetReceiptDetail(r.Context(), expenseID)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
			return
		}
		if rd == nil {
			writeJSON(w, http.StatusNotFound, ErrorResponse{Error: "receipt not found"})
			return
		}

		writeJSON(w, http.StatusOK, rd)
	}
}
