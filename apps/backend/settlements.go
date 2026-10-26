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
	CounterpartyID string  `json:"counterparty_id,omitempty"`
	PayeeID        string  `json:"payee_id,omitempty"`
	PayerID        string  `json:"payer_id,omitempty"`
	Amount         float64 `json:"amount"`
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

func (q *DBQueries) CreateSettlement(ctx context.Context, callerPID string, req CreateSettlementRequest) (*Settlement, error) {
	counterpartyID := req.CounterpartyID
	if counterpartyID == "" {
		if req.PayeeID != "" && req.PayeeID != callerPID {
			counterpartyID = req.PayeeID
		} else if req.PayerID != "" && req.PayerID != callerPID {
			counterpartyID = req.PayerID
		} else if req.PayeeID != "" {
			counterpartyID = req.PayeeID
		} else if req.PayerID != "" {
			counterpartyID = req.PayerID
		}
	}
	if counterpartyID == "" {
		return nil, fmt.Errorf("choose a valid person to settle with")
	}

	var claimedPID *string
	err := q.pool.QueryRow(ctx,
		`SELECT claimed_by_participant_id FROM public.contacts WHERE participant_id = $1`, counterpartyID,
	).Scan(&claimedPID)
	if err == nil && claimedPID != nil && *claimedPID != "" {
		counterpartyID = *claimedPID
	}

	if counterpartyID == callerPID {
		return nil, fmt.Errorf("cannot settle a balance with yourself")
	}
	if req.Amount <= 0 || !validateMaxDecimals(req.Amount, 2) {
		return nil, fmt.Errorf("enter an amount greater than zero with up to two decimal places")
	}
	amountPaise := int64(math.Round(req.Amount * 100))

	tx, err := q.pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("begin settlement transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	// Consistent ordered lock key to prevent race conditions and duplicate submissions
	p1, p2 := callerPID, counterpartyID
	if p1 > p2 {
		p1, p2 = p2, p1
	}
	lockKey := fmt.Sprintf("settle:%s:%s", p1, p2)
	if _, err := tx.Exec(ctx, `SELECT pg_advisory_xact_lock(hashtext($1))`, lockKey); err != nil {
		return nil, fmt.Errorf("acquire settlement lock: %w", err)
	}

	var (
		owedCallerToOther      int64
		owedOtherToCaller      int64
		confirmedCallerToOther int64
		confirmedOtherToCaller int64
		pendingCallerToOther   int64
		pendingOtherToCaller   int64
	)
	err = tx.QueryRow(ctx,
		`SELECT
			COALESCE(ROUND((SELECT amount_owed FROM public.pairwise_balances WHERE from_participant = $1 AND to_participant = $2) * 100), 0)::bigint,
			COALESCE(ROUND((SELECT amount_owed FROM public.pairwise_balances WHERE from_participant = $2 AND to_participant = $1) * 100), 0)::bigint,
			COALESCE(ROUND((SELECT SUM(amount) FROM public.settlements WHERE payer_participant_id = $1 AND payee_participant_id = $2 AND status = 'confirmed') * 100), 0)::bigint,
			COALESCE(ROUND((SELECT SUM(amount) FROM public.settlements WHERE payer_participant_id = $2 AND payee_participant_id = $1 AND status = 'confirmed') * 100), 0)::bigint,
			COALESCE(ROUND((SELECT SUM(amount) FROM public.settlements WHERE payer_participant_id = $1 AND payee_participant_id = $2 AND status = 'pending') * 100), 0)::bigint,
			COALESCE(ROUND((SELECT SUM(amount) FROM public.settlements WHERE payer_participant_id = $2 AND payee_participant_id = $1 AND status = 'pending') * 100), 0)::bigint`,
		callerPID, counterpartyID,
	).Scan(
		&owedCallerToOther,
		&owedOtherToCaller,
		&confirmedCallerToOther,
		&confirmedOtherToCaller,
		&pendingCallerToOther,
		&pendingOtherToCaller,
	)
	if err != nil {
		return nil, fmt.Errorf("check outstanding balance: %w", err)
	}

	callerOwesOtherConfirmed := (owedCallerToOther - owedOtherToCaller) - (confirmedCallerToOther - confirmedOtherToCaller)

	var payerID, payeeID, status string
	var confirmedAt *time.Time

	switch {
	case callerOwesOtherConfirmed > 0:
		// Caller is the debtor and owes money to counterparty
		payerID = callerPID
		payeeID = counterpartyID

		remainingPaise := callerOwesOtherConfirmed - pendingCallerToOther
		if remainingPaise <= 0 {
			if pendingCallerToOther > 0 {
				return nil, fmt.Errorf("a settlement of ₹%.2f is already pending confirmation", float64(pendingCallerToOther)/100)
			}
			return nil, fmt.Errorf("you do not owe this person right now")
		}
		if amountPaise > remainingPaise {
			return nil, fmt.Errorf("payment is more than the remaining balance of ₹%.2f", float64(remainingPaise)/100)
		}

		var payeeHasAccount bool
		if err := tx.QueryRow(ctx, `SELECT EXISTS(SELECT 1 FROM public.profiles WHERE participant_id = $1)`, payeeID).Scan(&payeeHasAccount); err != nil {
			return nil, fmt.Errorf("check payee account: %w", err)
		}
		if payeeHasAccount {
			status = "pending"
		} else {
			status = "confirmed"
			now := time.Now()
			confirmedAt = &now
		}

	case callerOwesOtherConfirmed < 0:
		// Counterparty owes money to caller. Caller is the payee confirming payment was received!
		payerID = counterpartyID
		payeeID = callerPID

		// If the debtor had already submitted a pending settlement covering this amount,
		// safely confirm it rather than creating a duplicate row.
		var pendingSettlementID string
		var pendingSettlementPaise int64
		err = tx.QueryRow(ctx,
			`SELECT id, CAST(ROUND(amount * 100) AS BIGINT)
			 FROM public.settlements
			 WHERE payer_participant_id = $1 AND payee_participant_id = $2 AND status = 'pending'
			 ORDER BY created_at ASC LIMIT 1`,
			counterpartyID, callerPID,
		).Scan(&pendingSettlementID, &pendingSettlementPaise)

		if err == nil && pendingSettlementID != "" {
			if amountPaise == pendingSettlementPaise {
				_, err = tx.Exec(ctx,
					`UPDATE public.settlements
					 SET status = 'confirmed', updated_at = now(), confirmed_at = now()
					 WHERE id = $1`,
					pendingSettlementID,
				)
				if err != nil {
					return nil, fmt.Errorf("confirm pending settlement: %w", err)
				}
				if err := tx.Commit(ctx); err != nil {
					return nil, fmt.Errorf("commit settlement tx: %w", err)
				}
				return q.GetSettlement(ctx, pendingSettlementID)
			}
		}

		otherOwesCallerConfirmed := -callerOwesOtherConfirmed
		remainingPaise := otherOwesCallerConfirmed - pendingOtherToCaller
		if remainingPaise <= 0 {
			return nil, fmt.Errorf("this person does not owe you right now")
		}
		if amountPaise > remainingPaise {
			return nil, fmt.Errorf("settlement is more than the remaining balance of ₹%.2f", float64(remainingPaise)/100)
		}

		status = "confirmed"
		now := time.Now()
		confirmedAt = &now

	default:
		return nil, fmt.Errorf("there is no outstanding balance between you and this person")
	}

	var id string
	err = tx.QueryRow(ctx,
		`INSERT INTO public.settlements (payer_participant_id, payee_participant_id, amount, status, confirmed_at)
		 VALUES ($1, $2, $3, $4, $5) RETURNING id`,
		payerID, payeeID, float64(amountPaise)/100, status, confirmedAt,
	).Scan(&id)
	if err != nil {
		return nil, fmt.Errorf("create settlement: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("commit settlement tx: %w", err)
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
