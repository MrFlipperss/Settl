package main

import (
	"context"
	"fmt"
	"math"
	"net/http"
	"time"
)

func (q *DBQueries) GetChanges(ctx context.Context, since time.Time, participantID string) (*ChangesResponse, error) {
	now := time.Now()

	expenses, err := q.GetChangedExpenses(ctx, since, participantID)
	if err != nil {
		return nil, fmt.Errorf("get changed expenses: %w", err)
	}

	lists, err := q.GetChangedLists(ctx, since, participantID)
	if err != nil {
		return nil, fmt.Errorf("get changed lists: %w", err)
	}

	contacts, err := q.GetChangedContacts(ctx, since, participantID)
	if err != nil {
		return nil, fmt.Errorf("get changed contacts: %w", err)
	}

	resp := &ChangesResponse{
		Expenses: expenses,
		Lists:    lists,
		Contacts: contacts,
		AsOf:     now,
	}
	return resp, nil
}

func (q *DBQueries) GetChangedExpenses(ctx context.Context, since time.Time, participantID string) ([]Expense, error) {
	query := `SELECT DISTINCT e.id, e.list_id, e.payer_id, e.amount, e.category, e.note,
	                  e.split_type, COALESCE(e.version, 1), e.created_at
		FROM public.expenses e
		LEFT JOIN public.expense_splits es ON es.expense_id = e.id
		WHERE (e.payer_id = $1 OR es.participant_id = $1)
		  AND e.created_at > $2
		ORDER BY e.created_at DESC`

	rows, err := q.pool.Query(ctx, query, participantID, since)
	if err != nil {
		return nil, fmt.Errorf("get changed expenses: %w", err)
	}
	defer rows.Close()

	var expenses []Expense
	for rows.Next() {
		var e Expense
		var listID *string
		var amountFloat float64
		if err := rows.Scan(&e.ID, &listID, &e.PayerID, &amountFloat, &e.Category, &e.Note, &e.SplitType, &e.Version, &e.CreatedAt); err != nil {
			return nil, fmt.Errorf("scan expense: %w", err)
		}
		e.Amount = int64(math.Round(amountFloat * 100))
		e.ListID = listID
		expenses = append(expenses, e)
	}
	return expenses, nil
}

func (q *DBQueries) GetChangedLists(ctx context.Context, since time.Time, participantID string) ([]List, error) {
	query := `SELECT DISTINCT l.id, l.account_number, l.name, l.created_by, l.created_at,
	                  (SELECT count(*) FROM public.list_members lm WHERE lm.list_id = l.id) AS member_count
		FROM public.lists l
		JOIN public.list_members lm ON lm.list_id = l.id
		WHERE lm.participant_id = $1 AND l.created_at > $2
		ORDER BY l.created_at DESC`

	rows, err := q.pool.Query(ctx, query, participantID, since)
	if err != nil {
		return nil, fmt.Errorf("get changed lists: %w", err)
	}
	defer rows.Close()

	var lists []List
	for rows.Next() {
		var list List
		if err := rows.Scan(&list.ID, &list.AccountNumber, &list.Name, &list.CreatedBy, &list.CreatedAt, &list.MemberCount); err != nil {
			return nil, fmt.Errorf("scan list: %w", err)
		}
		lists = append(lists, list)
	}
	return lists, nil
}

func (q *DBQueries) GetChangedContacts(ctx context.Context, since time.Time, participantID string) ([]Contact, error) {
	query := `SELECT c.participant_id, c.display_name, c.phone_number, c.created_by,
	                  c.claimed_by_participant_id, c.created_at
		FROM public.contacts c
		WHERE c.created_by = $1 AND c.created_at > $2
		ORDER BY c.created_at DESC`

	rows, err := q.pool.Query(ctx, query, participantID, since)
	if err != nil {
		return nil, fmt.Errorf("get changed contacts: %w", err)
	}
	defer rows.Close()

	var contacts []Contact
	for rows.Next() {
		var c Contact
		if err := rows.Scan(&c.ParticipantID, &c.DisplayName, &c.PhoneNumber, &c.CreatedBy, &c.ClaimedByParticipantID, &c.CreatedAt); err != nil {
			return nil, fmt.Errorf("scan contact: %w", err)
		}
		contacts = append(contacts, c)
	}
	return contacts, nil
}

func getChangesHandler(q *DBQueries) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		participantID := participantIDFromCtx(r.Context())
		if participantID == "" {
			writeJSON(w, http.StatusUnauthorized, ErrorResponse{Error: "unauthorized"})
			return
		}

		sinceStr := r.URL.Query().Get("since")
		if sinceStr == "" {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "query parameter 'since' is required (RFC3339 format)"})
			return
		}

		since, err := time.Parse(time.RFC3339, sinceStr)
		if err != nil {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "invalid 'since' format, use RFC3339 (e.g. 2025-01-01T00:00:00Z)"})
			return
		}

		changes, err := q.GetChanges(r.Context(), since, participantID)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
			return
		}
		if changes.Expenses == nil {
			changes.Expenses = []Expense{}
		}
		if changes.Lists == nil {
			changes.Lists = []List{}
		}
		if changes.Contacts == nil {
			changes.Contacts = []Contact{}
		}

		writeJSON(w, http.StatusOK, changes)
	}
}
