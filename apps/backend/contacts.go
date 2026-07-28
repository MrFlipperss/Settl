package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

func NormalizePhoneNumber(phone string) string {
	cleaned := ""
	for _, ch := range phone {
		if ch >= '0' && ch <= '9' {
			cleaned += string(ch)
		} else if ch == '+' && cleaned == "" {
			cleaned += string(ch)
		}
	}
	if len(cleaned) == 10 {
		return "+91" + cleaned
	}
	if len(cleaned) == 11 && cleaned[0] == '0' {
		return "+91" + cleaned[1:]
	}
	if len(cleaned) > 0 && cleaned[0] != '+' {
		return "+" + cleaned
	}
	return cleaned
}

func (q *DBQueries) CreateContact(ctx context.Context, req CreateContactRequest, createdBy string) (*Contact, error) {
	tx, err := q.pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback(ctx)

	normPhone := NormalizePhoneNumber(req.PhoneNumber)
	now := time.Now()

	var participantID string
	hasID := req.ID != nil && *req.ID != ""
	if hasID {
		err = tx.QueryRow(ctx,
			`INSERT INTO public.participants (id, kind) VALUES ($1, 'contact') RETURNING id`,
			*req.ID,
		).Scan(&participantID)
	} else {
		err = tx.QueryRow(ctx,
			`INSERT INTO public.participants (kind) VALUES ('contact') RETURNING id`,
		).Scan(&participantID)
	}
	if err != nil {
		return nil, fmt.Errorf("insert participant: %w", err)
	}

	contact := &Contact{
		ParticipantID: participantID,
		DisplayName:   req.DisplayName,
		PhoneNumber:   normPhone,
		CreatedBy:     createdBy,
		CreatedAt:     now,
	}

	_, err = tx.Exec(ctx,
		`INSERT INTO public.contacts (participant_id, display_name, phone_number, created_by)
		 VALUES ($1, $2, $3, $4)`,
		participantID, req.DisplayName, normPhone, createdBy,
	)
	if err != nil {
		return nil, fmt.Errorf("insert contact: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("commit tx: %w", err)
	}

	return contact, nil
}

func (q *DBQueries) ClaimContacts(ctx context.Context, phoneNumber, newParticipantID string) (int, error) {
	normPhone := NormalizePhoneNumber(phoneNumber)
	result, err := q.pool.Exec(ctx,
		`UPDATE public.contacts
		 SET claimed_by_participant_id = $1
		 WHERE phone_number = $2 AND claimed_by_participant_id IS NULL`,
		newParticipantID, normPhone,
	)
	if err != nil {
		return 0, fmt.Errorf("claim contacts: %w", err)
	}
	return int(result.RowsAffected()), nil
}

func (q *DBQueries) GetContact(ctx context.Context, participantID string) (*Contact, error) {
	row := q.pool.QueryRow(ctx,
		`SELECT participant_id, display_name, phone_number, created_by, claimed_by_participant_id, created_at
		 FROM public.contacts WHERE participant_id = $1`, participantID)

	var c Contact
	err := row.Scan(&c.ParticipantID, &c.DisplayName, &c.PhoneNumber, &c.CreatedBy, &c.ClaimedByParticipantID, &c.CreatedAt)
	if err != nil {
		return nil, fmt.Errorf("get contact: %w", err)
	}
	return &c, nil
}

func (q *DBQueries) SearchContacts(ctx context.Context, query string, limit int) ([]ContactSearchResult, error) {
	if limit <= 0 || limit > 50 {
		limit = 20
	}

	searchPattern := "%" + query + "%"
	rows, err := q.pool.Query(ctx,
		`SELECT c.participant_id,
		        COALESCE(p.display_name, c.display_name) AS display_name,
		        c.phone_number
		 FROM public.contacts c
		 LEFT JOIN public.profiles p ON p.participant_id = c.claimed_by_participant_id
		 WHERE c.deleted_at IS NULL
		   AND (c.display_name ILIKE $1 OR c.phone_number ILIKE $1)
		 ORDER BY c.display_name ASC
		 LIMIT $2`,
		searchPattern, limit,
	)
	if err != nil {
		return nil, fmt.Errorf("search contacts: %w", err)
	}
	defer rows.Close()

	var results []ContactSearchResult
	for rows.Next() {
		var r ContactSearchResult
		if err := rows.Scan(&r.ParticipantID, &r.DisplayName, &r.PhoneNumber); err != nil {
			return nil, fmt.Errorf("scan search result: %w", err)
		}
		results = append(results, r)
	}
	return results, nil
}

func searchContactsHandler(q *DBQueries) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		qp := r.URL.Query().Get("q")
		if qp == "" {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "query parameter 'q' is required"})
			return
		}

		results, err := q.SearchContacts(r.Context(), qp, 20)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
			return
		}
		if results == nil {
			results = []ContactSearchResult{}
		}

		writeJSON(w, http.StatusOK, results)
	}
}

func createContactHandler(q *DBQueries) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req CreateContactRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "invalid request body"})
			return
		}

		if req.DisplayName == "" || req.PhoneNumber == "" {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "display_name and phone_number are required"})
			return
		}

		createdBy := participantIDFromCtx(r.Context())
		if createdBy == "" {
			writeJSON(w, http.StatusUnauthorized, ErrorResponse{Error: "unauthorized"})
			return
		}

		contact, err := q.CreateContact(r.Context(), req, createdBy)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
			return
		}

		writeJSON(w, http.StatusCreated, contact)
	}
}

func claimContactsHandler(q *DBQueries) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req ClaimContactsRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "invalid request body"})
			return
		}

		if req.PhoneNumber == "" {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "phone_number is required"})
			return
		}

		newPID := participantIDFromCtx(r.Context())
		if newPID == "" {
			writeJSON(w, http.StatusUnauthorized, ErrorResponse{Error: "unauthorized"})
			return
		}

		claimed, err := q.ClaimContacts(r.Context(), req.PhoneNumber, newPID)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
			return
		}

		writeJSON(w, http.StatusOK, map[string]interface{}{
			"claimed": claimed,
			"message": fmt.Sprintf("%d contact(s) claimed", claimed),
		})
	}
}
