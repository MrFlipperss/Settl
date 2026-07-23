package main

import (
	"context"
	"fmt"
	"net/http"
)

type pairwiseBalanceRow struct {
	FromParticipant string
	ToParticipant   string
	AmountOwed      float64
}

func (q *DBQueries) GetPairwiseBalances(ctx context.Context, personID *string) ([]pairwiseBalanceRow, error) {
	query := `SELECT from_participant, to_participant, amount_owed
		FROM public.pairwise_balances`
	args := []interface{}{}

	if personID != nil {
		query += ` WHERE from_participant = $1 OR to_participant = $1`
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
		if err := rows.Scan(&b.FromParticipant, &b.ToParticipant, &b.AmountOwed); err != nil {
			return nil, fmt.Errorf("scan balance: %w", err)
		}
		balances = append(balances, b)
	}
	return balances, nil
}

func (q *DBQueries) GetProfileDisplayName(ctx context.Context, participantID string) (string, error) {
	var name string
	err := q.pool.QueryRow(ctx,
		`SELECT display_name FROM public.profiles WHERE participant_id = $1`, participantID,
	).Scan(&name)
	if err != nil {
		return participantID[:8], nil
	}
	return name, nil
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

		var totalOwed, totalOwing float64
		var breakdown []BalanceEntry

		for _, b := range balances {
			var entry BalanceEntry
			entry.Currency = "INR"

			if b.FromParticipant == participantID {
				// current user owes b.ToParticipant
				totalOwing += b.AmountOwed
				entry.UserID = b.ToParticipant
				entry.Amount = b.AmountOwed
				name, _ := q.GetProfileDisplayName(r.Context(), b.ToParticipant)
				entry.UserName = name
			} else if b.ToParticipant == participantID {
				// b.FromParticipant owes current user
				totalOwed += b.AmountOwed
				entry.UserID = b.FromParticipant
				entry.Amount = b.AmountOwed
				name, _ := q.GetProfileDisplayName(r.Context(), b.FromParticipant)
				entry.UserName = name
			} else if personID != nil {
				if b.FromParticipant == *personID {
					entry.UserID = b.ToParticipant
					entry.Amount = b.AmountOwed
				} else if b.ToParticipant == *personID {
					entry.UserID = b.FromParticipant
					entry.Amount = b.AmountOwed
				} else {
					continue
				}
				name, _ := q.GetProfileDisplayName(r.Context(), entry.UserID)
				entry.UserName = name
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
