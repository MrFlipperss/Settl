package main

import (
	"context"
	"crypto/rsa"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"math/big"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

type contextKey string

const (
	contextKeyUserID        = contextKey("userID")
	contextKeyParticipantID = contextKey("participantID")
)

type JSONWebKey struct {
	Kty string `json:"kty"`
	Kid string `json:"kid"`
	Use string `json:"use"`
	N   string `json:"n"`
	E   string `json:"e"`
	Alg string `json:"alg"`
}

type JWKS struct {
	Keys []JSONWebKey `json:"keys"`
}

type JWKSCache struct {
	mu        sync.RWMutex
	jwksURL   string
	keys      map[string]*rsa.PublicKey
	fetchedAt time.Time
	ttl       time.Duration
}

var globalJWKSCache *JWKSCache

func initJWKSCache(jwksURL string) *JWKSCache {
	return &JWKSCache{
		jwksURL: jwksURL,
		keys:    make(map[string]*rsa.PublicKey),
		ttl:     1 * time.Hour,
	}
}

func (c *JWKSCache) GetPublicKey(kid string) (*rsa.PublicKey, error) {
	c.mu.RLock()
	key, exists := c.keys[kid]
	fresh := time.Since(c.fetchedAt) < c.ttl
	c.mu.RUnlock()

	if exists && fresh {
		return key, nil
	}

	c.mu.Lock()
	defer c.mu.Unlock()

	// Double check
	if key, exists := c.keys[kid]; exists && time.Since(c.fetchedAt) < c.ttl {
		return key, nil
	}

	if c.jwksURL == "" {
		return nil, fmt.Errorf("no JWKS URL configured")
	}

	resp, err := http.Get(c.jwksURL)
	if err != nil {
		return nil, fmt.Errorf("fetch JWKS: %w", err)
	}
	defer resp.Body.Close()

	var jwks JWKS
	if err := json.NewDecoder(resp.Body).Decode(&jwks); err != nil {
		return nil, fmt.Errorf("decode JWKS: %w", err)
	}

	newKeys := make(map[string]*rsa.PublicKey)
	for _, k := range jwks.Keys {
		if k.Kty != "RSA" {
			continue
		}
		pubKey, err := parseRSAPublicKey(k.N, k.E)
		if err == nil {
			newKeys[k.Kid] = pubKey
		}
	}

	c.keys = newKeys
	c.fetchedAt = time.Now()

	pubKey, ok := c.keys[kid]
	if !ok {
		return nil, fmt.Errorf("key id %s not found in JWKS", kid)
	}
	return pubKey, nil
}

func parseRSAPublicKey(nStr, eStr string) (*rsa.PublicKey, error) {
	nBytes, err := base64.RawURLEncoding.DecodeString(nStr)
	if err != nil {
		return nil, err
	}
	eBytes, err := base64.RawURLEncoding.DecodeString(eStr)
	if err != nil {
		return nil, err
	}

	var eInt int
	for _, b := range eBytes {
		eInt = (eInt << 8) | int(b)
	}

	return &rsa.PublicKey{
		N: new(big.Int).SetBytes(nBytes),
		E: eInt,
	}, nil
}

func AuthMiddleware(jwtSecret string, db *DBQueries) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			tokenStr := extractBearerToken(r)
			if tokenStr == "" {
				writeJSON(w, http.StatusUnauthorized, ErrorResponse{Error: "missing authorization header"})
				return
			}

			token, err := jwt.Parse(tokenStr, func(token *jwt.Token) (interface{}, error) {
				if _, ok := token.Method.(*jwt.SigningMethodHMAC); ok {
					return []byte(jwtSecret), nil
				}
				if _, ok := token.Method.(*jwt.SigningMethodRSA); ok {
					kid, ok := token.Header["kid"].(string)
					if !ok {
						return nil, fmt.Errorf("missing kid header")
					}
					if globalJWKSCache != nil {
						return globalJWKSCache.GetPublicKey(kid)
					}
					return nil, fmt.Errorf("JWKS not initialized")
				}
				return nil, jwt.ErrSignatureInvalid
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
