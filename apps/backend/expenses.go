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

	splitType := req.SplitType

	var expenseID string
	createdAt := time.Now()
	if req.Timestamp != nil {
		createdAt = *req.Timestamp
	}

	category := "Uncategorized"
	if req.Category != nil {
		category = *req.Category
	}

	err = tx.QueryRow(ctx,
		`INSERT INTO public.expenses (list_id, payer_id, amount, category, note, split_type, created_at)
		 VALUES ($1, $2, $3, $4, $5, $6, $7)
		 RETURNING id`,
		req.GroupID, req.PayerID, req.Amount, category, req.Note, splitType, createdAt,
	).Scan(&expenseID)
	if err != nil {
		return nil, fmt.Errorf("insert expense: %w", err)
	}

	for _, s := range splits {
		_, err = tx.Exec(ctx,
			`INSERT INTO public.expense_splits (expense_id, participant_id, share_amount, raw_input)
			 VALUES ($1, $2, $3, $4)`,
			expenseID, s.ParticipantID, s.ShareAmount, s.RawInput,
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
		Amount:    req.Amount,
		Category:  category,
		Note:      req.Note,
		SplitType: splitType,
		CreatedAt: createdAt,
		Splits:    splits,
	}
	return expense, nil
}

func (q *DBQueries) GetExpense(ctx context.Context, id string) (*Expense, error) {
	row := q.pool.QueryRow(ctx,
		`SELECT id, list_id, payer_id, amount, category, note, split_type, created_at
		 FROM public.expenses WHERE id = $1`, id)

	var e Expense
	var listID *string
	err := row.Scan(&e.ID, &listID, &e.PayerID, &e.Amount, &e.Category, &e.Note, &e.SplitType, &e.CreatedAt)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("get expense: %w", err)
	}
	e.ListID = listID

	rows, err := q.pool.Query(ctx,
		`SELECT id, expense_id, participant_id, share_amount, raw_input
		 FROM public.expense_splits WHERE expense_id = $1`, id)
	if err != nil {
		return nil, fmt.Errorf("get splits: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var s Split
		if err := rows.Scan(&s.ID, &s.ExpenseID, &s.ParticipantID, &s.ShareAmount, &s.RawInput); err != nil {
			return nil, fmt.Errorf("scan split: %w", err)
		}
		e.Splits = append(e.Splits, s)
	}

	return &e, nil
}

func (q *DBQueries) ListExpenses(ctx context.Context, groupID *string, from, to *time.Time, participantID string) ([]Expense, error) {
	query := `SELECT DISTINCT e.id, e.list_id, e.payer_id, e.amount, e.category, e.note, e.split_type, e.created_at
		FROM public.expenses e
		LEFT JOIN public.expense_splits es ON es.expense_id = e.id
		WHERE (e.payer_id = $1 OR es.participant_id = $1)`
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
		if err := rows.Scan(&e.ID, &listID, &e.PayerID, &e.Amount, &e.Category, &e.Note, &e.SplitType, &e.CreatedAt); err != nil {
			return nil, fmt.Errorf("scan expense: %w", err)
		}
		e.ListID = listID
		expenses = append(expenses, e)
	}

	return expenses, nil
}

func createExpenseHandler(q *DBQueries) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req CreateExpenseRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "invalid request body"})
			return
		}

		if req.PayerID == "" || req.Amount <= 0 || len(req.Splits) == 0 {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "payer_id, amount, and splits are required"})
			return
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

		expense, err := q.GetExpense(r.Context(), id)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
			return
		}
		if expense == nil {
			writeJSON(w, http.StatusNotFound, ErrorResponse{Error: "expense not found"})
			return
		}

		writeJSON(w, http.StatusOK, expense)
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
		shareRupees := float64(r.SharePaise) / 100.0
		// Preserve the caller's raw input for audit purposes.
		var rawInput float64
		switch splitType {
		case SplitExact:
			if req.Splits[i].ExactAmount != nil {
				rawInput = *req.Splits[i].ExactAmount
			}
		case SplitPercentage:
			if req.Splits[i].Percentage != nil {
				rawInput = *req.Splits[i].Percentage
			}
		case SplitShares:
			if req.Splits[i].ShareCount != nil {
				rawInput = float64(*req.Splits[i].ShareCount)
			}
		default:
			rawInput = shareRupees
		}
		splits[i] = Split{
			ParticipantID: req.Splits[i].UserID,
			ShareAmount:   shareRupees,
			RawInput:      &rawInput,
		}
	}
	return splits, nil
}
