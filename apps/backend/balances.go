package main

import (
	"context"
	"fmt"
	"net/http"
)

type pairwiseBalanceRow struct {
	FromParticipant string
	FromDisplayName string
	ToParticipant   string
	ToDisplayName   string
	AmountOwedPaise int64
}

func safeUUIDDisplay(id string) string {
	if len(id) >= 8 {
		return id[:8]
	}
	return id
}

func (q *DBQueries) GetPairwiseBalances(ctx context.Context, personID *string) ([]pairwiseBalanceRow, error) {
	query := `SELECT b.from_participant, COALESCE(pf.display_name, ''),
	                 b.to_participant, COALESCE(pt.display_name, ''),
	                 CAST(b.amount_owed * 100 AS BIGINT)
		FROM public.pairwise_balances b
		LEFT JOIN public.profiles pf ON pf.participant_id = b.from_participant
		LEFT JOIN public.profiles pt ON pt.participant_id = b.to_participant`
	args := []interface{}{}

	if personID != nil {
		query += ` WHERE b.from_participant = $1 OR b.to_participant = $1`
		args = append(args, *personID)
	}

	rows, err := q.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("query pairwise_balances: %w", err)
	}
	defer rows.Close()

	var balances []pairwiseBalanceRow
	for rows.Next() {
		var b pairwiseBalanceRow
		if err := rows.Scan(&b.FromParticipant, &b.FromDisplayName, &b.ToParticipant, &b.ToDisplayName, &b.AmountOwedPaise); err != nil {
			return nil, fmt.Errorf("scan balance: %w", err)
		}
		if b.FromDisplayName == "" {
			b.FromDisplayName = safeUUIDDisplay(b.FromParticipant)
		}
		if b.ToDisplayName == "" {
			b.ToDisplayName = safeUUIDDisplay(b.ToParticipant)
		}
		balances = append(balances, b)
	}
	return balances, nil
}

func getBalancesHandler(q *DBQueries) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		participantID := participantIDFromCtx(r.Context())
		if participantID == "" {
			writeJSON(w, http.StatusUnauthorized, ErrorResponse{Error: "unauthorized"})
			return
		}

		var personID *string
		if p := r.URL.Query().Get("personID"); p != "" {
			personID = &p
		}

		balances, err := q.GetPairwiseBalances(r.Context(), personID)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
			return
		}

		var totalOwed, totalOwing int64
		var breakdown []BalanceEntry

		for _, b := range balances {
			var entry BalanceEntry
			entry.Currency = "INR"

			if b.FromParticipant == participantID {
				// current user owes b.ToParticipant
				totalOwing += b.AmountOwedPaise
				entry.UserID = b.ToParticipant
				entry.Amount = b.AmountOwedPaise
				entry.UserName = b.ToDisplayName
			} else if b.ToParticipant == participantID {
				// b.FromParticipant owes current user
				totalOwed += b.AmountOwedPaise
				entry.UserID = b.FromParticipant
				entry.Amount = b.AmountOwedPaise
				entry.UserName = b.FromDisplayName
			} else if personID != nil {
				if b.FromParticipant == *personID {
					entry.UserID = b.ToParticipant
					entry.Amount = b.AmountOwedPaise
					entry.UserName = b.ToDisplayName
				} else if b.ToParticipant == *personID {
					entry.UserID = b.FromParticipant
					entry.Amount = b.AmountOwedPaise
					entry.UserName = b.FromDisplayName
				} else {
					continue
				}
			} else {
				continue
			}

			breakdown = append(breakdown, entry)
		}

		resp := BalancesResponse{
			TotalOwed:  totalOwed,
			TotalOwing: totalOwing,
			Net:        totalOwed - totalOwing,
			Breakdown:  breakdown,
		}

		if resp.Breakdown == nil {
			resp.Breakdown = []BalanceEntry{}
		}

		writeJSON(w, http.StatusOK, resp)
	}
}
