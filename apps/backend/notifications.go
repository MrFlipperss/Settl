package main

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
)

type Notification struct {
	ID                 string     `json:"id"`
	Type               string     `json:"type"`
	Title              string     `json:"title"`
	Body               string     `json:"body"`
	ExpenseID          *string    `json:"expense_id,omitempty"`
	ContactID          *string    `json:"contact_id,omitempty"`
	ActorParticipantID string     `json:"actor_participant_id"`
	ActorDisplayName   string     `json:"actor_display_name"`
	CreatedAt          time.Time  `json:"created_at"`
	ReadAt             *time.Time `json:"read_at,omitempty"`
}

type NotificationsResponse struct {
	Notifications []Notification `json:"notifications"`
	UnreadCount   int            `json:"unread_count"`
}

func notificationRecipientPredicate() string {
	return `(n.recipient_participant_id = $1 OR EXISTS (
		SELECT 1 FROM public.contacts c
		WHERE c.participant_id = n.recipient_participant_id
		  AND c.claimed_by_participant_id = $1
	))`
}

func (q *DBQueries) ListNotifications(ctx context.Context, participantID string) (*NotificationsResponse, error) {
	query := fmt.Sprintf(`SELECT n.id, n.type, n.title, n.body, n.expense_id, n.contact_id,
			n.actor_participant_id,
			COALESCE(NULLIF(p.display_name, ''), NULLIF(c.display_name, ''), 'Someone'),
			n.created_at, n.read_at
		FROM public.notifications n
		LEFT JOIN public.profiles p ON p.participant_id = n.actor_participant_id
		LEFT JOIN public.contacts c ON c.participant_id = n.actor_participant_id AND c.deleted_at IS NULL
		WHERE %s
		ORDER BY n.created_at DESC
		LIMIT 50`, notificationRecipientPredicate())
	rows, err := q.pool.Query(ctx, query, participantID)
	if err != nil {
		return nil, fmt.Errorf("list notifications: %w", err)
	}
	defer rows.Close()

	response := &NotificationsResponse{Notifications: []Notification{}}
	for rows.Next() {
		var item Notification
		if err := rows.Scan(&item.ID, &item.Type, &item.Title, &item.Body, &item.ExpenseID, &item.ContactID,
			&item.ActorParticipantID, &item.ActorDisplayName, &item.CreatedAt, &item.ReadAt); err != nil {
			return nil, fmt.Errorf("scan notification: %w", err)
		}
		response.Notifications = append(response.Notifications, item)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate notifications: %w", err)
	}

	countQuery := fmt.Sprintf(`SELECT COUNT(*) FROM public.notifications n
		WHERE %s AND n.read_at IS NULL`, notificationRecipientPredicate())
	if err := q.pool.QueryRow(ctx, countQuery, participantID).Scan(&response.UnreadCount); err != nil {
		return nil, fmt.Errorf("count unread notifications: %w", err)
	}
	return response, nil
}

func (q *DBQueries) MarkNotificationRead(ctx context.Context, participantID, notificationID string) error {
	query := fmt.Sprintf(`UPDATE public.notifications n SET read_at = COALESCE(n.read_at, now())
		WHERE n.id = $2 AND %s`, notificationRecipientPredicate())
	_, err := q.pool.Exec(ctx, query, participantID, notificationID)
	if err != nil {
		return fmt.Errorf("mark notification read: %w", err)
	}
	return nil
}

func (q *DBQueries) MarkAllNotificationsRead(ctx context.Context, participantID string) error {
	query := fmt.Sprintf(`UPDATE public.notifications n SET read_at = now()
		WHERE n.read_at IS NULL AND %s`, notificationRecipientPredicate())
	_, err := q.pool.Exec(ctx, query, participantID)
	if err != nil {
		return fmt.Errorf("mark all notifications read: %w", err)
	}
	return nil
}

func listNotificationsHandler(q *DBQueries) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		participantID := participantIDFromCtx(r.Context())
		if participantID == "" {
			writeJSON(w, http.StatusUnauthorized, ErrorResponse{Error: "unauthorized"})
			return
		}
		response, err := q.ListNotifications(r.Context(), participantID)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, ErrorResponse{Error: "could not load notifications"})
			return
		}
		writeJSON(w, http.StatusOK, response)
	}
}

func markNotificationReadHandler(q *DBQueries) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		participantID := participantIDFromCtx(r.Context())
		if participantID == "" {
			writeJSON(w, http.StatusUnauthorized, ErrorResponse{Error: "unauthorized"})
			return
		}
		if err := q.MarkNotificationRead(r.Context(), participantID, chi.URLParam(r, "notificationID")); err != nil {
			writeJSON(w, http.StatusInternalServerError, ErrorResponse{Error: "could not update notification"})
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}
}

func markAllNotificationsReadHandler(q *DBQueries) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		participantID := participantIDFromCtx(r.Context())
		if participantID == "" {
			writeJSON(w, http.StatusUnauthorized, ErrorResponse{Error: "unauthorized"})
			return
		}
		if err := q.MarkAllNotificationsRead(r.Context(), participantID); err != nil {
			writeJSON(w, http.StatusInternalServerError, ErrorResponse{Error: "could not update notifications"})
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}
}
