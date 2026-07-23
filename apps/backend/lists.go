package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
)

func (q *DBQueries) CreateList(ctx context.Context, name string, createdBy string) (*List, error) {
	tx, err := q.pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback(ctx)

	var list List
	err = tx.QueryRow(ctx,
		`INSERT INTO public.lists (name, created_by)
		 VALUES ($1, $2)
		 RETURNING id, account_number, name, created_by, created_at`,
		name, createdBy,
	).Scan(&list.ID, &list.AccountNumber, &list.Name, &list.CreatedBy, &list.CreatedAt)
	if err != nil {
		return nil, fmt.Errorf("insert list: %w", err)
	}

	_, err = tx.Exec(ctx,
		`INSERT INTO public.list_members (list_id, participant_id) VALUES ($1, $2)`,
		list.ID, createdBy,
	)
	if err != nil {
		return nil, fmt.Errorf("add creator to list: %w", err)
	}

	list.MemberCount = 1

	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("commit tx: %w", err)
	}

	return &list, nil
}

func (q *DBQueries) GetList(ctx context.Context, id string) (*List, error) {
	row := q.pool.QueryRow(ctx,
		`SELECT l.id, l.account_number, l.name, l.created_by, l.created_at,
		        (SELECT count(*) FROM public.list_members lm WHERE lm.list_id = l.id) AS member_count
		 FROM public.lists l WHERE l.id = $1`, id)

	var list List
	err := row.Scan(&list.ID, &list.AccountNumber, &list.Name, &list.CreatedBy, &list.CreatedAt, &list.MemberCount)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("get list: %w", err)
	}
	return &list, nil
}

func (q *DBQueries) ListListsByMember(ctx context.Context, participantID string) ([]List, error) {
	rows, err := q.pool.Query(ctx,
		`SELECT l.id, l.account_number, l.name, l.created_by, l.created_at,
		        (SELECT count(*) FROM public.list_members lm WHERE lm.list_id = l.id) AS member_count
		 FROM public.lists l
		 JOIN public.list_members lm ON lm.list_id = l.id
		 WHERE lm.participant_id = $1
		 ORDER BY l.created_at DESC`, participantID)
	if err != nil {
		return nil, fmt.Errorf("list lists: %w", err)
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

func (q *DBQueries) AddListMember(ctx context.Context, listID, participantID string) error {
	_, err := q.pool.Exec(ctx,
		`INSERT INTO public.list_members (list_id, participant_id)
		 VALUES ($1, $2)
		 ON CONFLICT DO NOTHING`,
		listID, participantID,
	)
	if err != nil {
		return fmt.Errorf("add list member: %w", err)
	}
	return nil
}

func createListHandler(q *DBQueries) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req CreateGroupRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "invalid request body"})
			return
		}

		if req.Name == "" {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "name is required"})
			return
		}

		createdBy := participantIDFromCtx(r.Context())
		if createdBy == "" {
			writeJSON(w, http.StatusUnauthorized, ErrorResponse{Error: "unauthorized"})
			return
		}

		list, err := q.CreateList(r.Context(), req.Name, createdBy)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
			return
		}

		writeJSON(w, http.StatusCreated, list)
	}
}

func listListsHandler(q *DBQueries) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		pid := participantIDFromCtx(r.Context())
		if pid == "" {
			writeJSON(w, http.StatusUnauthorized, ErrorResponse{Error: "unauthorized"})
			return
		}

		lists, err := q.ListListsByMember(r.Context(), pid)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
			return
		}
		if lists == nil {
			lists = []List{}
		}

		writeJSON(w, http.StatusOK, lists)
	}
}

func getListHandler(q *DBQueries) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "groupID")
		if id == "" {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "groupID is required"})
			return
		}

		list, err := q.GetList(r.Context(), id)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
			return
		}
		if list == nil {
			writeJSON(w, http.StatusNotFound, ErrorResponse{Error: "group not found"})
			return
		}

		writeJSON(w, http.StatusOK, list)
	}
}

func addListMemberHandler(q *DBQueries) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		listID := chi.URLParam(r, "groupID")
		if listID == "" {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "groupID is required"})
			return
		}

		var req AddMemberRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "invalid request body"})
			return
		}

		if req.UserID == "" {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "user_id is required"})
			return
		}

		// user_id in AddMemberRequest refers to participant_id
		if err := q.AddListMember(r.Context(), listID, req.UserID); err != nil {
			writeJSON(w, http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
			return
		}

		w.WriteHeader(http.StatusCreated)
	}
}
