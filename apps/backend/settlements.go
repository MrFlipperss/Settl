package main

import (
	"context"
	"encoding/json"
	"fmt"
	"math"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
)

type Settlement struct {
	ID          string    `json:"id"`
	PayerID     string    `json:"payer_id"`
	PayerName   string    `json:"payer_name"`
	PayeeID     string    `json:"payee_id"`
	PayeeName   string    `json:"payee_name"`
	AmountPaise int64     `json:"amount_paise"`
	Status      string    `json:"status"`
	CreatedAt   time.Time `json:"created_at"`
}

type CreateSettlementRequest struct {
	PayeeID string  `json:"payee_id"`
	Amount  float64 `json:"amount"`
}

type UpdateSettlementRequest struct {
	Status string `json:"status"`
}

func (q *DBQueries) ListSettlements(ctx context.Context, participantID string) ([]Settlement, error) {
	rows, err := q.pool.Query(ctx,
		`SELECT s.id, s.payer_participant_id,
		        COALESCE(NULLIF(pp.display_name, ''), NULLIF(pc.display_name, ''), 'Settl person'),
		        s.payee_participant_id,
		        COALESCE(NULLIF(rp.display_name, ''), NULLIF(rc.display_name, ''), 'Settl person'),
		        CAST(s.amount * 100 AS BIGINT), s.status, s.created_at
		 FROM public.settlements s
		 LEFT JOIN public.profiles pp ON pp.participant_id = s.payer_participant_id
		 LEFT JOIN public.contacts pc ON pc.participant_id = s.payer_participant_id AND pc.deleted_at IS NULL
		 LEFT JOIN public.profiles rp ON rp.participant_id = s.payee_participant_id
		 LEFT JOIN public.contacts rc ON rc.participant_id = s.payee_participant_id AND rc.deleted_at IS NULL
		 WHERE s.payer_participant_id = $1 OR s.payee_participant_id = $1
		 ORDER BY s.created_at DESC LIMIT 100`, participantID)
	if err != nil {
		return nil, fmt.Errorf("list settlements: %w", err)
	}
	defer rows.Close()

	settlements := make([]Settlement, 0)
	for rows.Next() {
		var settlement Settlement
		if err := rows.Scan(&settlement.ID, &settlement.PayerID, &settlement.PayerName,
			&settlement.PayeeID, &settlement.PayeeName, &settlement.AmountPaise,
			&settlement.Status, &settlement.CreatedAt); err != nil {
			return nil, fmt.Errorf("scan settlement: %w", err)
		}
		settlements = append(settlements, settlement)
	}
	return settlements, rows.Err()
}

func (q *DBQueries) CreateSettlement(ctx context.Context, payerID string, req CreateSettlementRequest) (*Settlement, error) {
	if req.PayeeID == "" || req.PayeeID == payerID {
		return nil, fmt.Errorf("choose a valid person to pay")
	}
	if req.Amount <= 0 || !validateMaxDecimals(req.Amount, 2) {
		return nil, fmt.Errorf("enter an amount greater than zero with up to two decimal places")
	}
	amountPaise := int64(math.Round(req.Amount * 100))
	var outstandingPaise int64
	err := q.pool.QueryRow(ctx,
		`SELECT COALESCE(CAST(ROUND((
			COALESCE((SELECT amount_owed FROM public.pairwise_balances WHERE from_participant = $1 AND to_participant = $2), 0)
			- COALESCE((SELECT amount_owed FROM public.pairwise_balances WHERE from_participant = $2 AND to_participant = $1), 0)
			- COALESCE((SELECT SUM(amount) FROM public.settlements WHERE payer_participant_id = $1 AND payee_participant_id = $2 AND status IN ('pending', 'confirmed')), 0)
			+ COALESCE((SELECT SUM(amount) FROM public.settlements WHERE payer_participant_id = $2 AND payee_participant_id = $1 AND status IN ('pending', 'confirmed')), 0)
		) * 100) AS BIGINT), 0)`, payerID, req.PayeeID,
	).Scan(&outstandingPaise)
	if err != nil {
		return nil, fmt.Errorf("check outstanding balance: %w", err)
	}
	if outstandingPaise <= 0 {
		return nil, fmt.Errorf("you do not owe this person right now")
	}
	if amountPaise > outstandingPaise {
		return nil, fmt.Errorf("payment is more than the remaining balance of ₹%.2f", float64(outstandingPaise)/100)
	}

	status := "pending"
	var payeeHasAccount bool
	if err := q.pool.QueryRow(ctx, `SELECT EXISTS(SELECT 1 FROM public.profiles WHERE participant_id = $1)`, req.PayeeID).Scan(&payeeHasAccount); err != nil {
		return nil, fmt.Errorf("check payee account: %w", err)
	}
	if !payeeHasAccount {
		// An unregistered contact cannot confirm in the app; the payer's
		// explicit "I've sent it" action records the settlement directly.
		status = "confirmed"
	}

	var id string
	err = q.pool.QueryRow(ctx,
		`INSERT INTO public.settlements (payer_participant_id, payee_participant_id, amount, status)
		 VALUES ($1, $2, $3, $4) RETURNING id`,
		payerID, req.PayeeID, float64(amountPaise)/100, status,
	).Scan(&id)
	if err != nil {
		return nil, fmt.Errorf("create settlement: %w", err)
	}
	return q.GetSettlement(ctx, id)
}

func (q *DBQueries) GetSettlement(ctx context.Context, id string) (*Settlement, error) {
	var settlement Settlement
	err := q.pool.QueryRow(ctx,
		`SELECT s.id, s.payer_participant_id,
		        COALESCE(NULLIF(pp.display_name, ''), NULLIF(pc.display_name, ''), 'Settl person'),
		        s.payee_participant_id,
		        COALESCE(NULLIF(rp.display_name, ''), NULLIF(rc.display_name, ''), 'Settl person'),
		        CAST(s.amount * 100 AS BIGINT), s.status, s.created_at
		 FROM public.settlements s
		 LEFT JOIN public.profiles pp ON pp.participant_id = s.payer_participant_id
		 LEFT JOIN public.contacts pc ON pc.participant_id = s.payer_participant_id AND pc.deleted_at IS NULL
		 LEFT JOIN public.profiles rp ON rp.participant_id = s.payee_participant_id
		 LEFT JOIN public.contacts rc ON rc.participant_id = s.payee_participant_id AND rc.deleted_at IS NULL
		 WHERE s.id = $1`, id,
	).Scan(&settlement.ID, &settlement.PayerID, &settlement.PayerName,
		&settlement.PayeeID, &settlement.PayeeName, &settlement.AmountPaise,
		&settlement.Status, &settlement.CreatedAt)
	if err != nil {
		return nil, fmt.Errorf("get settlement: %w", err)
	}
	return &settlement, nil
}

func (q *DBQueries) UpdateSettlementStatus(ctx context.Context, settlementID, payeeID, status string) error {
	if status != "confirmed" && status != "declined" {
		return fmt.Errorf("status must be confirmed or declined")
	}
	result, err := q.pool.Exec(ctx,
		`UPDATE public.settlements SET status = $1, updated_at = now(), confirmed_at = CASE WHEN $1 = 'confirmed' THEN now() ELSE confirmed_at END
		 WHERE id = $2 AND payee_participant_id = $3 AND status = 'pending'`,
		status, settlementID, payeeID,
	)
	if err != nil {
		return fmt.Errorf("update settlement: %w", err)
	}
	if result.RowsAffected() == 0 {
		return fmt.Errorf("settlement not found or no longer pending")
	}
	return nil
}

func listSettlementsHandler(q *DBQueries) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		participantID := participantIDFromCtx(r.Context())
		settlements, err := q.ListSettlements(r.Context(), participantID)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, ErrorResponse{Error: "could not load settlements"})
			return
		}
		writeJSON(w, http.StatusOK, settlements)
	}
}

func createSettlementHandler(q *DBQueries) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req CreateSettlementRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "invalid request body"})
			return
		}
		settlement, err := q.CreateSettlement(r.Context(), participantIDFromCtx(r.Context()), req)
		if err != nil {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: err.Error()})
			return
		}
		writeJSON(w, http.StatusCreated, settlement)
	}
}

func updateSettlementHandler(q *DBQueries) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req UpdateSettlementRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "invalid request body"})
			return
		}
		if err := q.UpdateSettlementStatus(r.Context(), chi.URLParam(r, "settlementID"), participantIDFromCtx(r.Context()), req.Status); err != nil {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: err.Error()})
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}
}
