package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
)

func (q *DBQueries) CreateExpense(ctx context.Context, req CreateExpenseRequest, splits []Split) (*Expense, error) {
	tx, err := q.pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback(ctx)

	amountPaise := int64(math.Round(req.Amount * 100))
	splitType := req.SplitType

	now := time.Now()
	createdAt := now
	if req.Timestamp != nil {
		createdAt = *req.Timestamp
	}

	category := "Uncategorized"
	if req.Category != nil {
		category = *req.Category
	}

	amountRupees := float64(amountPaise) / 100.0

	// Use client-supplied ID if provided, otherwise let DB generate it
	hasID := req.ID != nil && *req.ID != ""
	var expenseID string
	if hasID {
		expenseID = *req.ID
	}

	if req.IdempotencyKey != nil && *req.IdempotencyKey != "" {
		if hasID {
			err = tx.QueryRow(ctx,
				`INSERT INTO public.expenses (id, list_id, payer_id, amount, category, note, split_type, created_at, updated_at, idempotency_key, version)
				 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, 1)
				 ON CONFLICT (idempotency_key) DO NOTHING
				 RETURNING id`,
				expenseID, req.GroupID, req.PayerID, amountRupees, category, req.Note, splitType, createdAt, now, req.IdempotencyKey,
			).Scan(&expenseID)
		} else {
			err = tx.QueryRow(ctx,
				`INSERT INTO public.expenses (list_id, payer_id, amount, category, note, split_type, created_at, updated_at, idempotency_key, version)
				 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 1)
				 ON CONFLICT (idempotency_key) DO NOTHING
				 RETURNING id`,
				req.GroupID, req.PayerID, amountRupees, category, req.Note, splitType, createdAt, now, req.IdempotencyKey,
			).Scan(&expenseID)
		}
		if err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				tx.Rollback(ctx)
				var existingID string
				_ = q.pool.QueryRow(ctx, `SELECT id FROM public.expenses WHERE idempotency_key = $1`, *req.IdempotencyKey).Scan(&existingID)
				return q.GetExpense(ctx, existingID)
			}
			return nil, fmt.Errorf("insert expense with idempotency: %w", err)
		}
	} else {
		if hasID {
			err = tx.QueryRow(ctx,
				`INSERT INTO public.expenses (id, list_id, payer_id, amount, category, note, split_type, created_at, updated_at, version)
				 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 1)
				 RETURNING id`,
				expenseID, req.GroupID, req.PayerID, amountRupees, category, req.Note, splitType, createdAt, now,
			).Scan(&expenseID)
		} else {
			err = tx.QueryRow(ctx,
				`INSERT INTO public.expenses (list_id, payer_id, amount, category, note, split_type, created_at, updated_at, version)
				 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 1)
				 RETURNING id`,
				req.GroupID, req.PayerID, amountRupees, category, req.Note, splitType, createdAt, now,
			).Scan(&expenseID)
		}
		if err != nil {
			return nil, fmt.Errorf("insert expense: %w", err)
		}
	}

	for _, s := range splits {
		shareRupees := float64(s.ShareAmount) / 100.0
		_, err = tx.Exec(ctx,
			`INSERT INTO public.expense_splits (expense_id, participant_id, share_amount, raw_input, created_at, updated_at)
			 VALUES ($1, $2, $3, $4, $5, $6)`,
			expenseID, s.ParticipantID, shareRupees, s.RawInput, now, now,
		)
		if err != nil {
			return nil, fmt.Errorf("insert split: %w", err)
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("commit tx: %w", err)
	}

	expense := &Expense{
		ID:        expenseID,
		ListID:    req.GroupID,
		PayerID:   req.PayerID,
		Amount:    amountPaise,
		Category:  category,
		Note:      req.Note,
		SplitType: splitType,
		Version:   1,
		CreatedAt: createdAt,
		UpdatedAt: &now,
		Splits:    splits,
	}
	return expense, nil
}

func (q *DBQueries) UpdateExpense(ctx context.Context, id string, req CreateExpenseRequest, splits []Split, expectedVersion int) (*Expense, error) {
	tx, err := q.pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback(ctx)

	amountPaise := int64(math.Round(req.Amount * 100))
	category := "Uncategorized"
	if req.Category != nil {
		category = *req.Category
	}

	now := time.Now()
	amountRupees := float64(amountPaise) / 100.0
	query := `UPDATE public.expenses
		 SET payer_id = $1, amount = $2, category = $3, note = $4, split_type = $5, version = version + 1, updated_at = $6
		 WHERE id = $7`
	args := []interface{}{req.PayerID, amountRupees, category, req.Note, req.SplitType, now, id}

	if expectedVersion > 0 {
		query += ` AND version = $8`
		args = append(args, expectedVersion)
	}

	res, err := tx.Exec(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("update expense: %w", err)
	}
	if res.RowsAffected() == 0 {
		return nil, fmt.Errorf("conflict or expense not found")
	}

	// Delete old splits and insert updated ones
	_, err = tx.Exec(ctx, `UPDATE public.expense_splits SET deleted_at = $1 WHERE expense_id = $2`, now, id)
	if err != nil {
		return nil, fmt.Errorf("soft delete old splits: %w", err)
	}

	for _, s := range splits {
		shareRupees := float64(s.ShareAmount) / 100.0
		_, err = tx.Exec(ctx,
			`INSERT INTO public.expense_splits (expense_id, participant_id, share_amount, raw_input, created_at, updated_at)
			 VALUES ($1, $2, $3, $4, $5, $5)`,
			id, s.ParticipantID, shareRupees, s.RawInput, now,
		)
		if err != nil {
			return nil, fmt.Errorf("insert updated split: %w", err)
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("commit update tx: %w", err)
	}

	return q.GetExpense(ctx, id)
}

func (q *DBQueries) DeleteExpense(ctx context.Context, id string) error {
	tx, err := q.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback(ctx)

	// Clean up attached receipt details
	_, _ = tx.Exec(ctx, `DELETE FROM public.receipt_details WHERE expense_id = $1`, id)

	// Clean up splits
	_, err = tx.Exec(ctx, `DELETE FROM public.expense_splits WHERE expense_id = $1`, id)
	if err != nil {
		return fmt.Errorf("delete splits: %w", err)
	}

	// Delete expense
	res, err := tx.Exec(ctx, `DELETE FROM public.expenses WHERE id = $1`, id)
	if err != nil {
		return fmt.Errorf("delete expense: %w", err)
	}
	if res.RowsAffected() == 0 {
		return pgx.ErrNoRows
	}

	return tx.Commit(ctx)
}

func (q *DBQueries) GetExpense(ctx context.Context, id string) (*Expense, error) {
	row := q.pool.QueryRow(ctx,
		`SELECT id, list_id, payer_id, amount, category, note, split_type, COALESCE(version, 1), created_at, updated_at
		 FROM public.expenses WHERE id = $1`, id)

	var e Expense
	var listID *string
	var amountFloat float64
	err := row.Scan(&e.ID, &listID, &e.PayerID, &amountFloat, &e.Category, &e.Note, &e.SplitType, &e.Version, &e.CreatedAt, &e.UpdatedAt)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("get expense: %w", err)
	}
	e.Amount = int64(math.Round(amountFloat * 100))
	e.ListID = listID

	rows, err := q.pool.Query(ctx,
		`SELECT id, expense_id, participant_id, share_amount, raw_input, created_at, updated_at
		 FROM public.expense_splits WHERE expense_id = $1 AND deleted_at IS NULL`, id)
	if err != nil {
		return nil, fmt.Errorf("get splits: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var s Split
		var shareFloat float64
		if err := rows.Scan(&s.ID, &s.ExpenseID, &s.ParticipantID, &shareFloat, &s.RawInput, &s.CreatedAt, &s.UpdatedAt); err != nil {
			return nil, fmt.Errorf("scan split: %w", err)
		}
		s.ShareAmount = int64(math.Round(shareFloat * 100))
		e.Splits = append(e.Splits, s)
	}

	return &e, nil
}

func (q *DBQueries) ListExpenses(ctx context.Context, groupID *string, from, to *time.Time, participantID string) ([]Expense, error) {
	query := `SELECT DISTINCT e.id, e.list_id, e.payer_id, e.amount, e.category, e.note, e.split_type, COALESCE(e.version, 1), e.created_at, e.updated_at
		FROM public.expenses e
		LEFT JOIN public.expense_splits es ON es.expense_id = e.id
		WHERE e.deleted_at IS NULL AND (e.payer_id = $1 OR es.participant_id = $1)`
	args := []interface{}{participantID}
	argIdx := 2

	if groupID != nil {
		query += fmt.Sprintf(` AND e.list_id = $%d`, argIdx)
		args = append(args, *groupID)
		argIdx++
	}
	if from != nil {
		query += fmt.Sprintf(` AND e.created_at >= $%d`, argIdx)
		args = append(args, *from)
		argIdx++
	}
	if to != nil {
		query += fmt.Sprintf(` AND e.created_at <= $%d`, argIdx)
		args = append(args, *to)
		argIdx++
	}

	query += ` ORDER BY e.created_at DESC`

	rows, err := q.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("list expenses: %w", err)
	}
	defer rows.Close()

	var expenses []Expense
	for rows.Next() {
		var e Expense
		var listID *string
		var amountFloat float64
		if err := rows.Scan(&e.ID, &listID, &e.PayerID, &amountFloat, &e.Category, &e.Note, &e.SplitType, &e.Version, &e.CreatedAt, &e.UpdatedAt); err != nil {
			return nil, fmt.Errorf("scan expense: %w", err)
		}
		e.Amount = int64(math.Round(amountFloat * 100))
		e.ListID = listID
		expenses = append(expenses, e)
	}

	return expenses, nil
}

func validateMaxDecimals(val float64, maxDecimals int) bool {
	scaled := val * math.Pow10(maxDecimals)
	return math.Abs(scaled-math.Round(scaled)) < 1e-6
}

func createExpenseHandler(q *DBQueries) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req CreateExpenseRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "invalid request body"})
			return
		}

		// Read Idempotency-Key header if not in JSON body
		if req.IdempotencyKey == nil || *req.IdempotencyKey == "" {
			if key := r.Header.Get("Idempotency-Key"); key != "" {
				req.IdempotencyKey = &key
			}
		}

		callerPID := participantIDFromCtx(r.Context())
		if callerPID == "" {
			writeJSON(w, http.StatusUnauthorized, ErrorResponse{Error: "unauthorized"})
			return
		}
		req.PayerID = callerPID

		if req.Amount <= 0 || len(req.Splits) == 0 {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "amount and splits are required"})
			return
		}

		if !validateMaxDecimals(req.Amount, 2) {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "amount cannot have more than 2 decimal places"})
			return
		}

		// Verify membership if group expense
		if req.GroupID != nil && *req.GroupID != "" {
			inGroup, err := q.IsUserInGroup(r.Context(), *req.GroupID, callerPID)
			if err != nil || !inGroup {
				writeJSON(w, http.StatusForbidden, ErrorResponse{Error: "user does not belong to group"})
				return
			}
		}

		splits, err := resolveSplits(req)
		if err != nil {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: err.Error()})
			return
		}

		expense, err := q.CreateExpense(r.Context(), req, splits)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
			return
		}

		writeJSON(w, http.StatusCreated, expense)
	}
}

func getExpenseHandler(q *DBQueries) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "expenseID")
		if id == "" {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "expenseID is required"})
			return
		}

		callerPID := participantIDFromCtx(r.Context())

		expense, err := q.GetExpense(r.Context(), id)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
			return
		}
		if expense == nil {
			writeJSON(w, http.StatusNotFound, ErrorResponse{Error: "expense not found"})
			return
		}

		// Authorization Check: Verify caller is payer, participant in split, or member of group
		isParticipant := expense.PayerID == callerPID
		if !isParticipant {
			for _, s := range expense.Splits {
				if s.ParticipantID == callerPID {
					isParticipant = true
					break
				}
			}
		}
		if !isParticipant && expense.ListID != nil && *expense.ListID != "" {
			inGroup, err := q.IsUserInGroup(r.Context(), *expense.ListID, callerPID)
			if err == nil && inGroup {
				isParticipant = true
			}
		}

		if !isParticipant {
			writeJSON(w, http.StatusForbidden, ErrorResponse{Error: "access denied: user does not belong to this expense or group"})
			return
		}

		writeJSON(w, http.StatusOK, expense)
	}
}

func updateExpenseHandler(q *DBQueries) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "expenseID")
		if id == "" {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "expenseID is required"})
			return
		}

		callerPID := participantIDFromCtx(r.Context())
		existing, err := q.GetExpense(r.Context(), id)
		if err != nil || existing == nil {
			writeJSON(w, http.StatusNotFound, ErrorResponse{Error: "expense not found"})
			return
		}

		if existing.PayerID != callerPID {
			writeJSON(w, http.StatusForbidden, ErrorResponse{Error: "only payer can edit expense"})
			return
		}

		var req CreateExpenseRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "invalid request body"})
			return
		}

		req.PayerID = callerPID

		if !validateMaxDecimals(req.Amount, 2) {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "amount cannot have more than 2 decimal places"})
			return
		}

		splits, err := resolveSplits(req)
		if err != nil {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: err.Error()})
			return
		}

		updated, err := q.UpdateExpense(r.Context(), id, req, splits, 0)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
			return
		}

		writeJSON(w, http.StatusOK, updated)
	}
}

func deleteExpenseHandler(q *DBQueries) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "expenseID")
		if id == "" {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "expenseID is required"})
			return
		}

		callerPID := participantIDFromCtx(r.Context())
		existing, err := q.GetExpense(r.Context(), id)
		if err != nil || existing == nil {
			writeJSON(w, http.StatusNotFound, ErrorResponse{Error: "expense not found"})
			return
		}

		if existing.PayerID != callerPID {
			writeJSON(w, http.StatusForbidden, ErrorResponse{Error: "only payer can delete expense"})
			return
		}

		if err := q.DeleteExpense(r.Context(), id); err != nil {
			writeJSON(w, http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
			return
		}

		w.WriteHeader(http.StatusNoContent)
	}
}

func listExpensesHandler(q *DBQueries) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		participantID := participantIDFromCtx(r.Context())

		var groupID *string
		if g := r.URL.Query().Get("groupID"); g != "" {
			groupID = &g
		}

		var from, to *time.Time
		if f := r.URL.Query().Get("from"); f != "" {
			t, err := time.Parse(time.RFC3339, f)
			if err == nil {
				from = &t
			}
		}
		if t := r.URL.Query().Get("to"); t != "" {
			parsed, err := time.Parse(time.RFC3339, t)
			if err == nil {
				to = &parsed
			}
		}

		expenses, err := q.ListExpenses(r.Context(), groupID, from, to, participantID)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
			return
		}
		if expenses == nil {
			expenses = []Expense{}
		}

		writeJSON(w, http.StatusOK, expenses)
	}
}

func resolveSplits(req CreateExpenseRequest) ([]Split, error) {
	count := len(req.Splits)
	if count == 0 {
		return nil, fmt.Errorf("splits must not be empty")
	}

	splitType := SplitType(req.SplitType)

	// Convert total from rupees (float64) to paise (int64) for exact integer arithmetic.
	totalPaise := int64(math.Round(req.Amount * 100))

	// Build SplitInput slice from the request, mapping per-type fields to RawValue.
	inputs := make([]SplitInput, count)
	for i, s := range req.Splits {
		inp := SplitInput{Participant: s.UserID}
		switch splitType {
		case SplitExact:
			if s.ExactAmount == nil {
				return nil, fmt.Errorf("exact_amount required for exact split (participant index %d)", i)
			}
			inp.RawValue = int64(math.Round(*s.ExactAmount * 100)) // rupees → paise
		case SplitPercentage:
			if s.Percentage == nil {
				return nil, fmt.Errorf("percentage required for percentage split (participant index %d)", i)
			}
			// Caller supplies 0–100 (e.g. 33.33); convert to basis points for integer maths.
			inp.RawValue = int64(math.Round(*s.Percentage * 100)) // e.g. 33.33 → 3333 bps
		case SplitShares:
			if s.ShareCount == nil {
				return nil, fmt.Errorf("share_count required for shares split (participant index %d)", i)
			}
			inp.RawValue = int64(*s.ShareCount)
			// SplitEqual: RawValue is unused, zero is fine.
		}
		inputs[i] = inp
	}

	resolved, err := ResolveSplit(splitType, totalPaise, inputs)
	if err != nil {
		return nil, err
	}

	splits := make([]Split, count)
	for i, r := range resolved {
		var rawInput int64
		switch splitType {
		case SplitExact:
			if req.Splits[i].ExactAmount != nil {
				rawInput = int64(math.Round(*req.Splits[i].ExactAmount * 100))
			}
		case SplitPercentage:
			if req.Splits[i].Percentage != nil {
				rawInput = int64(math.Round(*req.Splits[i].Percentage * 100))
			}
		case SplitShares:
			if req.Splits[i].ShareCount != nil {
				rawInput = int64(*req.Splits[i].ShareCount)
			}
		default:
			rawInput = r.SharePaise
		}
		splits[i] = Split{
			ParticipantID: req.Splits[i].UserID,
			ShareAmount:   r.SharePaise,
			RawInput:      &rawInput,
		}
	}
	return splits, nil
}
