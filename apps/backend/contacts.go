package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/jackc/pgx/v5"
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

	// Prevent adding oneself as a contact
	var creatorPhone string
	_ = tx.QueryRow(ctx, `SELECT phone_number FROM public.profiles WHERE participant_id = $1`, createdBy).Scan(&creatorPhone)
	if creatorPhone != "" && normPhone == creatorPhone {
		return nil, fmt.Errorf("cannot add yourself as a contact")
	}

	// Idempotency: check if an active contact with this phone already exists for createdBy
	var existing Contact
	var existingClaimedPID *string
	lookupErr := tx.QueryRow(ctx,
		`SELECT c.participant_id, COALESCE(NULLIF(p.display_name, ''), c.display_name),
		        c.phone_number, c.claimed_by_participant_id IS NOT NULL, c.created_by,
		        c.claimed_by_participant_id, c.created_at, c.updated_at, c.deleted_at, c.version
		 FROM public.contacts c
		 LEFT JOIN public.profiles p ON p.participant_id = c.claimed_by_participant_id
		 WHERE c.created_by = $1 AND c.phone_number = $2 AND c.deleted_at IS NULL
		 ORDER BY c.created_at DESC LIMIT 1`, createdBy, normPhone,
	).Scan(&existing.ParticipantID, &existing.DisplayName, &existing.PhoneNumber,
		&existing.IsRegistered, &existing.CreatedBy, &existingClaimedPID,
		&existing.CreatedAt, &existing.UpdatedAt, &existing.DeletedAt, &existing.Version)
	if lookupErr == nil {
		if existingClaimedPID != nil {
			existing.ParticipantID = *existingClaimedPID
			existing.ClaimedByParticipantID = existingClaimedPID
		}
		if err := tx.Commit(ctx); err != nil {
			return nil, fmt.Errorf("commit tx: %w", err)
		}
		return &existing, nil
	}

	var registeredParticipantID *string
	var registeredName string
	err = tx.QueryRow(ctx,
		`SELECT participant_id, display_name FROM public.profiles WHERE phone_number = $1`, normPhone,
	).Scan(&registeredParticipantID, &registeredName)
	if err != nil && err != pgx.ErrNoRows {
		return nil, fmt.Errorf("check registered contact: %w", err)
	}
	if err == pgx.ErrNoRows {
		registeredParticipantID = nil
		registeredName = ""
	}

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

	returnPID := participantID
	if registeredParticipantID != nil {
		returnPID = *registeredParticipantID
	}

	contact := &Contact{
		ParticipantID:          returnPID,
		DisplayName:            req.DisplayName,
		PhoneNumber:            normPhone,
		IsRegistered:           registeredParticipantID != nil,
		CreatedBy:              createdBy,
		ClaimedByParticipantID: registeredParticipantID,
		CreatedAt:              now,
		UpdatedAt:              &now,
		Version:                1,
	}

	_, err = tx.Exec(ctx,
		`INSERT INTO public.contacts (participant_id, display_name, phone_number, created_by, claimed_by_participant_id, created_at, updated_at, version)
		 VALUES ($1, $2, $3, $4, $5, $6, $6, 1)`,
		participantID, req.DisplayName, normPhone, createdBy, registeredParticipantID, now,
	)
	if err != nil {
		return nil, fmt.Errorf("insert contact: %w", err)
	}

	if registeredParticipantID == nil || *registeredParticipantID != createdBy {
		var actorName string
		if err := tx.QueryRow(ctx, `SELECT display_name FROM public.profiles WHERE participant_id = $1`, createdBy).Scan(&actorName); err != nil {
			return nil, fmt.Errorf("load notification actor: %w", err)
		}
		_, err = tx.Exec(ctx,
			`INSERT INTO public.notifications
				(recipient_participant_id, actor_participant_id, contact_id, type, title, body)
			 VALUES ($1, $2, $3, 'contact_added', $4, $5)
			 ON CONFLICT (recipient_participant_id, contact_id, type) WHERE contact_id IS NOT NULL DO NOTHING`,
			participantID, createdBy, participantID,
			contactNotificationTitle(actorName, registeredParticipantID != nil),
			contactNotificationBody(actorName, registeredParticipantID != nil),
		)
		if err != nil {
			return nil, fmt.Errorf("insert contact notification: %w", err)
		}
		if registeredParticipantID != nil {
			contact.DisplayName = registeredName
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("commit tx: %w", err)
	}

	return contact, nil
}

func contactNotificationTitle(actorName string, registered bool) string {
	if registered {
		return fmt.Sprintf("%s added you on Settl", actorName)
	}
	return fmt.Sprintf("%s invited you to Settl", actorName)
}

func contactNotificationBody(actorName string, registered bool) string {
	if registered {
		return fmt.Sprintf("%s added you as a contact for shared expenses.", actorName)
	}
	return fmt.Sprintf("%s added you as a contact. Join Settl to see shared expenses and connect.", actorName)
}

func (q *DBQueries) ClaimContacts(ctx context.Context, phoneNumber, newParticipantID string) (int, error) {
	normPhone := NormalizePhoneNumber(phoneNumber)
	now := time.Now()

	tx, err := q.pool.Begin(ctx)
	if err != nil {
		return 0, fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback(ctx)

	result, err := tx.Exec(ctx,
		`UPDATE public.contacts
		 SET claimed_by_participant_id = $1, updated_at = $2
		 WHERE phone_number = $3 AND (claimed_by_participant_id IS NULL OR claimed_by_participant_id != $1)`,
		newParticipantID, now, normPhone,
	)
	if err != nil {
		return 0, fmt.Errorf("claim contacts: %w", err)
	}

	// Reconcile list_members for any contacts that were claimed
	_, err = tx.Exec(ctx,
		`INSERT INTO public.list_members (list_id, participant_id, updated_at)
		 SELECT lm.list_id, $1, $2
		 FROM public.list_members lm
		 JOIN public.contacts c ON c.participant_id = lm.participant_id
		 WHERE c.claimed_by_participant_id = $1
		 ON CONFLICT DO NOTHING`,
		newParticipantID, now,
	)
	if err != nil {
		return 0, fmt.Errorf("reconcile list_members insert: %w", err)
	}

	_, err = tx.Exec(ctx,
		`DELETE FROM public.list_members lm
		 USING public.contacts c
		 WHERE lm.participant_id = c.participant_id
		   AND c.claimed_by_participant_id = $1`,
		newParticipantID,
	)
	if err != nil {
		return 0, fmt.Errorf("reconcile list_members delete old: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return 0, fmt.Errorf("commit tx: %w", err)
	}

	return int(result.RowsAffected()), nil
}

func (q *DBQueries) GetContact(ctx context.Context, participantID string) (*Contact, error) {
	row := q.pool.QueryRow(ctx,
		`SELECT COALESCE(c.claimed_by_participant_id, c.participant_id),
		        COALESCE(NULLIF(p.display_name, ''), c.display_name),
		        c.phone_number, c.created_by, c.claimed_by_participant_id,
		        c.claimed_by_participant_id IS NOT NULL, c.created_at, c.updated_at, c.deleted_at, c.version
		 FROM public.contacts c
		 LEFT JOIN public.profiles p ON p.participant_id = c.claimed_by_participant_id
		 WHERE c.participant_id = $1 OR c.claimed_by_participant_id = $1
		 ORDER BY c.created_at DESC
		 LIMIT 1`, participantID)

	var c Contact
	err := row.Scan(&c.ParticipantID, &c.DisplayName, &c.PhoneNumber, &c.CreatedBy, &c.ClaimedByParticipantID, &c.IsRegistered, &c.CreatedAt, &c.UpdatedAt, &c.DeletedAt, &c.Version)
	if err != nil {
		return nil, fmt.Errorf("get contact: %w", err)
	}
	return &c, nil
}

func (q *DBQueries) ListContacts(ctx context.Context, createdBy string) ([]Contact, error) {
	rows, err := q.pool.Query(ctx,
		`WITH distinct_contacts AS (
			SELECT DISTINCT ON (COALESCE(c.claimed_by_participant_id, c.participant_id))
			       COALESCE(c.claimed_by_participant_id, c.participant_id) AS participant_id,
			       COALESCE(NULLIF(p.display_name, ''), c.display_name) AS display_name,
			       c.phone_number,
			       (c.claimed_by_participant_id IS NOT NULL) AS is_registered,
			       c.created_by,
			       c.claimed_by_participant_id,
			       c.created_at,
			       c.updated_at,
			       c.deleted_at,
			       c.version
			FROM public.contacts c
			LEFT JOIN public.profiles p ON p.participant_id = c.claimed_by_participant_id
			WHERE c.created_by = $1
			  AND c.deleted_at IS NULL
			  AND (c.claimed_by_participant_id IS NULL OR c.claimed_by_participant_id != $1)
			ORDER BY COALESCE(c.claimed_by_participant_id, c.participant_id), c.created_at DESC
		)
		SELECT participant_id, display_name, phone_number, is_registered, created_by,
		       claimed_by_participant_id, created_at, updated_at, deleted_at, version
		FROM distinct_contacts
		ORDER BY display_name ASC, created_at DESC`,
		createdBy,
	)
	if err != nil {
		return nil, fmt.Errorf("list contacts: %w", err)
	}
	defer rows.Close()

	contacts := make([]Contact, 0)
	for rows.Next() {
		var contact Contact
		if err := rows.Scan(&contact.ParticipantID, &contact.DisplayName, &contact.PhoneNumber,
			&contact.IsRegistered, &contact.CreatedBy, &contact.ClaimedByParticipantID,
			&contact.CreatedAt, &contact.UpdatedAt, &contact.DeletedAt, &contact.Version); err != nil {
			return nil, fmt.Errorf("scan contact: %w", err)
		}
		contacts = append(contacts, contact)
	}
	return contacts, rows.Err()
}

func (q *DBQueries) SearchContacts(ctx context.Context, query string, limit int, createdBy string) ([]ContactSearchResult, error) {
	if limit <= 0 || limit > 50 {
		limit = 20
	}

	searchPattern := "%" + query + "%"
	rows, err := q.pool.Query(ctx,
		`WITH distinct_contacts AS (
			SELECT DISTINCT ON (COALESCE(c.claimed_by_participant_id, c.participant_id))
			       COALESCE(c.claimed_by_participant_id, c.participant_id) AS participant_id,
			       COALESCE(NULLIF(p.display_name, ''), c.display_name) AS display_name,
			       c.phone_number,
			       (c.claimed_by_participant_id IS NOT NULL) AS is_registered
			FROM public.contacts c
			LEFT JOIN public.profiles p ON p.participant_id = c.claimed_by_participant_id
			WHERE c.created_by = $2
			  AND c.deleted_at IS NULL
			  AND (c.claimed_by_participant_id IS NULL OR c.claimed_by_participant_id != $2)
			  AND (COALESCE(NULLIF(p.display_name, ''), c.display_name) ILIKE $1 OR c.phone_number ILIKE $1)
			ORDER BY COALESCE(c.claimed_by_participant_id, c.participant_id), c.created_at DESC
		)
		SELECT participant_id, display_name, phone_number, is_registered
		FROM distinct_contacts
		ORDER BY display_name ASC
		LIMIT $3`,
		searchPattern, createdBy, limit,
	)
	if err != nil {
		return nil, fmt.Errorf("search contacts: %w", err)
	}
	defer rows.Close()

	var results []ContactSearchResult
	for rows.Next() {
		var r ContactSearchResult
		if err := rows.Scan(&r.ParticipantID, &r.DisplayName, &r.PhoneNumber, &r.IsRegistered); err != nil {
			return nil, fmt.Errorf("scan search result: %w", err)
		}
		results = append(results, r)
	}
	return results, nil
}

func listContactsHandler(q *DBQueries) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		participantID := participantIDFromCtx(r.Context())
		if participantID == "" {
			writeJSON(w, http.StatusUnauthorized, ErrorResponse{Error: "unauthorized"})
			return
		}
		contacts, err := q.ListContacts(r.Context(), participantID)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, ErrorResponse{Error: "could not load contacts"})
			return
		}
		writeJSON(w, http.StatusOK, contacts)
	}
}

func searchContactsHandler(q *DBQueries) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		qp := r.URL.Query().Get("q")
		if qp == "" {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "query parameter 'q' is required"})
			return
		}

		results, err := q.SearchContacts(r.Context(), qp, 20, participantIDFromCtx(r.Context()))
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
			if req.ID != nil && *req.ID != "" {
				existing, lookupErr := q.GetContact(r.Context(), *req.ID)
				if lookupErr == nil && existing != nil && existing.CreatedBy == createdBy {
					writeJSON(w, http.StatusOK, existing)
					return
				}
			}
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

		// Security: verify the authenticated user is claiming contacts for their OWN phone number
		var callerPhone string
		err := q.pool.QueryRow(r.Context(),
			`SELECT phone_number FROM public.profiles WHERE participant_id = $1`, newPID,
		).Scan(&callerPhone)
		if err != nil {
			writeJSON(w, http.StatusUnauthorized, ErrorResponse{Error: "profile not found"})
			return
		}

		if NormalizePhoneNumber(req.PhoneNumber) != callerPhone {
			writeJSON(w, http.StatusForbidden, ErrorResponse{Error: "you can only claim contacts matching your registered phone number"})
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
