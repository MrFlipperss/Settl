package main

import (
	"context"
	"net/http"
	"strings"

	"github.com/golang-jwt/jwt/v5"
)

type contextKey string

const (
	contextKeyUserID        = contextKey("userID")
	contextKeyParticipantID = contextKey("participantID")
)

func AuthMiddleware(jwtSecret string, db *DBQueries) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			tokenStr := extractBearerToken(r)
			if tokenStr == "" {
				writeJSON(w, http.StatusUnauthorized, ErrorResponse{Error: "missing authorization header"})
				return
			}

			token, err := jwt.Parse(tokenStr, func(token *jwt.Token) (interface{}, error) {
				if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
					return nil, jwt.ErrSignatureInvalid
				}
				return []byte(jwtSecret), nil
			})
			if err != nil || !token.Valid {
				writeJSON(w, http.StatusUnauthorized, ErrorResponse{Error: "invalid token"})
				return
			}

			claims, ok := token.Claims.(jwt.MapClaims)
			if !ok {
				writeJSON(w, http.StatusUnauthorized, ErrorResponse{Error: "invalid token claims"})
				return
			}

			userID, ok := claims["sub"].(string)
			if !ok || userID == "" {
				writeJSON(w, http.StatusUnauthorized, ErrorResponse{Error: "invalid subject"})
				return
			}

			participantID, err := db.GetParticipantIDByUserID(r.Context(), userID)
			if err != nil {
				writeJSON(w, http.StatusUnauthorized, ErrorResponse{Error: "user not found"})
				return
			}

			ctx := context.WithValue(r.Context(), contextKeyUserID, userID)
			ctx = context.WithValue(ctx, contextKeyParticipantID, participantID)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

func extractBearerToken(r *http.Request) string {
	auth := r.Header.Get("Authorization")
	if !strings.HasPrefix(auth, "Bearer ") {
		return ""
	}
	return strings.TrimPrefix(auth, "Bearer ")
}

func userIDFromCtx(ctx context.Context) string {
	v, _ := ctx.Value(contextKeyUserID).(string)
	return v
}

func participantIDFromCtx(ctx context.Context) string {
	v, _ := ctx.Value(contextKeyParticipantID).(string)
	return v
}
