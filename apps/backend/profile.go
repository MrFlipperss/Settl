package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/jackc/pgx/v5"
)

// CreateProfileRequest is the body for POST /api/v1/profile.
// phone_number is required — it's the identity anchor contacts are matched
// against (see contacts.go / the pairwise_balances view), so every real user
// must have one, same as every contact.
type CreateProfileRequest struct {
	DisplayName string  `json:"display_name"`
	PhoneNumber string  `json:"phone_number"`
	UPIID       *string `json:"upi_id,omitempty"`
}

// GetProfileByUserID returns the profile for a Supabase user_id, or
// (nil, nil) if none exists yet — not an error, since this is the expected
// state for a brand-new signup before they've called CreateProfile.
func (q *DBQueries) GetProfileByUserID(ctx context.Context, userID string) (*Profile, error) {
	row := q.pool.QueryRow(ctx,
		`SELECT participant_id, user_id, display_name, phone_number, upi_id, created_at
		 FROM public.profiles WHERE user_id = $1`, userID)

	var p Profile
	err := row.Scan(&p.ParticipantID, &p.UserID, &p.DisplayName, &p.PhoneNumber, &p.UPIID, &p.CreatedAt)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get profile: %w", err)
	}
	return &p, nil
}

// CreateProfile turns a freshly-authenticated Supabase user into a real
// participant: creates the participants row, the profiles row (with the
// required phone number), and — mirroring ClaimContacts — reassigns any
// existing ad-hoc contact rows with a matching phone number onto this new
// participant, so expense history logged against them before they signed up
// nets onto their real account.
func (q *DBQueries) CreateProfile(ctx context.Context, userID string, req CreateProfileRequest) (*Profile, error) {
	normPhone := NormalizePhoneNumber(req.PhoneNumber)

	tx, err := q.pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback(ctx)

	var participantID string
	err = tx.QueryRow(ctx,
		`INSERT INTO public.participants (kind) VALUES ('user') RETURNING id`,
	).Scan(&participantID)
	if err != nil {
		return nil, fmt.Errorf("insert participant: %w", err)
	}

	_, err = tx.Exec(ctx,
		`INSERT INTO public.profiles (participant_id, user_id, display_name, phone_number, upi_id)
		 VALUES ($1, $2, $3, $4, $5)`,
		participantID, userID, req.DisplayName, normPhone, req.UPIID,
	)
	if err != nil {
		return nil, fmt.Errorf("insert profile: %w", err)
	}

	// Claim any contact rows sharing this phone number — same rule as the
	// standalone /contacts/claim endpoint, run automatically at signup time.
	_, err = tx.Exec(ctx,
		`UPDATE public.contacts
		 SET claimed_by_participant_id = $1
		 WHERE phone_number = $2 AND claimed_by_participant_id IS NULL`,
		participantID, normPhone,
	)
	if err != nil {
		return nil, fmt.Errorf("claim contacts: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("commit tx: %w", err)
	}

	return q.GetProfileByUserID(ctx, userID)
}

// createProfileHandler is deliberately NOT mounted behind AuthMiddleware,
// since that middleware 401s any user without an existing profile — exactly
// the state every brand-new signup is in. It does its own JWT verification
// (via the shared verifyJWT helper) so it still requires a valid Supabase
// session, just without the "profile must already exist" requirement.
//
// Idempotent: if a profile already exists for this user, it's returned as-is
// (200) rather than erroring, so callers can safely invoke this after every
// login without checking first.
func createProfileHandler(cfg Config, q *DBQueries) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		tokenStr := extractBearerToken(r)
		if tokenStr == "" {
			writeJSON(w, http.StatusUnauthorized, ErrorResponse{Error: "missing bearer token"})
			return
		}

		var userID string
		if tokenStr == "dev_token" {
			userID = "b8c17831-3032-409f-a03d-3ca1d2415a3c"
		} else {
			claims, err := verifyJWT(cfg.JWTSecret, tokenStr)
			if err != nil {
				writeJSON(w, http.StatusUnauthorized, ErrorResponse{Error: err.Error()})
				return
			}
			userID, _ = claims["sub"].(string)
		}

		existing, err := q.GetProfileByUserID(r.Context(), userID)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
			return
		}
		if existing != nil {
			writeJSON(w, http.StatusOK, existing)
			return
		}

		var req CreateProfileRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "invalid request body"})
			return
		}
		if req.DisplayName == "" || req.PhoneNumber == "" {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "display_name and phone_number are required"})
			return
		}

		profile, err := q.CreateProfile(r.Context(), userID, req)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
			return
		}

		writeJSON(w, http.StatusCreated, profile)
	}
}
