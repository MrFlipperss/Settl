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

		// Net all rows against each counterparty into a single signed amount
		// before building the breakdown. pairwise_balances stores one
		// directional row per (from, to) pair per expense; without netting
		// here, two people who owe each other from different expenses would
		// show up as two separate, seemingly-conflicting breakdown entries
		// instead of one net figure.
		//
		// netPaise > 0 means the counterparty owes the reference person
		// (the authenticated viewer, or personID when set as a query param);
		// netPaise < 0 means the reference person owes them.
		type netEntry struct {
			userID   string
			userName string
			netPaise int64
		}
		order := []string{}
		nets := make(map[string]*netEntry)

		addNet := func(counterpartyID, counterpartyName string, signedPaise int64) {
			e, ok := nets[counterpartyID]
			if !ok {
				e = &netEntry{userID: counterpartyID, userName: counterpartyName}
				nets[counterpartyID] = e
				order = append(order, counterpartyID)
			}
			e.netPaise += signedPaise
		}

		reference := participantID
		if personID != nil {
			reference = *personID
		}

		for _, b := range balances {
			switch {
			case b.FromParticipant == reference && b.ToParticipant == reference:
				continue
			case b.FromParticipant == reference:
				// reference owes b.ToParticipant
				addNet(b.ToParticipant, b.ToDisplayName, -b.AmountOwedPaise)
			case b.ToParticipant == reference:
				// b.FromParticipant owes reference
				addNet(b.FromParticipant, b.FromDisplayName, b.AmountOwedPaise)
			default:
				continue
			}
		}

		var totalOwed, totalOwing int64
		breakdown := make([]BalanceEntry, 0, len(order))
		for _, id := range order {
			e := nets[id]
			if e.netPaise == 0 {
				// Fully settled with this person once netted — omit rather
				// than show a stale +/-0 line.
				continue
			}
			amount := e.netPaise
			if amount < 0 {
				amount = -amount
			}
			if e.netPaise > 0 {
				totalOwed += amount
			} else {
				totalOwing += amount
			}
			breakdown = append(breakdown, BalanceEntry{
				UserID:   e.userID,
				UserName: e.userName,
				Amount:   amount,
				Currency: "INR",
			})
		}

		resp := BalancesResponse{
			TotalOwed:  totalOwed,
			TotalOwing: totalOwing,
			Net:        totalOwed - totalOwing,
			Breakdown:  breakdown,
		}

		writeJSON(w, http.StatusOK, resp)
	}
}
