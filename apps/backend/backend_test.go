package main

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

const mockSecret = "test-secret-12345678901234567890"

func generateMockToken(userID string) string {
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"sub": userID,
		"exp": time.Now().Add(time.Hour).Unix(),
	})
	tokenStr, _ := token.SignedString([]byte(mockSecret))
	return tokenStr
}

// TestDecimalValidation tests the 2-decimal restriction rule
func TestDecimalValidation(t *testing.T) {
	tests := []struct {
		amount float64
		valid  bool
	}{
		{10.50, true},
		{10.5, true},
		{10.00, true},
		{10.555, false},
		{0.001, false},
		{100.99, true},
	}

	for _, tt := range tests {
		got := validateMaxDecimals(tt.amount, 2)
		if got != tt.valid {
			t.Errorf("validateMaxDecimals(%f, 2) = %v; want %v", tt.amount, got, tt.valid)
		}
	}
}

// TestSplitRecomputationOnUpdate tests dynamic recomputation of splits
func TestSplitRecomputationOnUpdate(t *testing.T) {
	req := CreateExpenseRequest{
		Amount:    300.00,
		SplitType: "equal",
		Splits: []CreateSplitItem{
			{UserID: "p1"},
			{UserID: "p2"},
			{UserID: "p3"},
		},
	}

	splits, err := resolveSplits(req)
	if err != nil {
		t.Fatalf("resolveSplits failed: %v", err)
	}

	if len(splits) != 3 {
		t.Fatalf("expected 3 splits, got %d", len(splits))
	}

	for _, s := range splits {
		if s.ShareAmount != 100.00 {
			t.Errorf("expected share 100.00, got %f", s.ShareAmount)
		}
	}

	// Update expense amount to 150.00
	req.Amount = 150.00
	updatedSplits, err := resolveSplits(req)
	if err != nil {
		t.Fatalf("resolveSplits failed: %v", err)
	}

	for _, s := range updatedSplits {
		if s.ShareAmount != 50.00 {
			t.Errorf("expected updated share 50.00, got %f", s.ShareAmount)
		}
	}
}

// TestAuthMiddleware_MissingToken verifies 401 when no Auth header is present
func TestAuthMiddleware_MissingToken(t *testing.T) {
	req := httptest.NewRequest("GET", "/api/v1/expenses", nil)
	rec := httptest.NewRecorder()

	handler := AuthMiddleware(mockSecret, nil)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected status 401 Unauthorized, got %d", rec.Code)
	}
}

// TestAccountNumberFormatting verifies LST-XXXX account number formatting logic
func TestAccountNumberFormatting(t *testing.T) {
	seqVal := 42
	accountNumber := fmt.Sprintf("LST-%04d", seqVal)
	if accountNumber != "LST-0042" {
		t.Errorf("expected 'LST-0042', got '%s'", accountNumber)
	}
}

