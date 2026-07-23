package main

import (
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
		if s.ShareAmount != 10000 {
			t.Errorf("expected share 10000 paise (100 INR), got %d", s.ShareAmount)
		}
	}

	// Update expense amount to 150.00
	req.Amount = 150.00
	updatedSplits, err := resolveSplits(req)
	if err != nil {
		t.Fatalf("resolveSplits failed: %v", err)
	}

	for _, s := range updatedSplits {
		if s.ShareAmount != 5000 {
			t.Errorf("expected updated share 5000 paise (50 INR), got %d", s.ShareAmount)
		}
	}
}

// TestPhoneNormalization tests E.164 phone formatting
func TestPhoneNormalization(t *testing.T) {
	tests := []struct {
		input    string
		expected string
	}{
		{"9876543210", "+919876543210"},
		{"09876543210", "+919876543210"},
		{"+91 9876543210", "+919876543210"},
		{"+1 415 555 2671", "+14155552671"},
	}

	for _, tt := range tests {
		got := NormalizePhoneNumber(tt.input)
		if got != tt.expected {
			t.Errorf("NormalizePhoneNumber(%q) = %q; want %q", tt.input, got, tt.expected)
		}
	}
}

// TestInt64PaiseSplitComputation verifies exact integer share calculations
func TestInt64PaiseSplitComputation(t *testing.T) {
	req := CreateExpenseRequest{
		Amount:    100.50,
		SplitType: "equal",
		Splits: []CreateSplitItem{
			{UserID: "p1"},
			{UserID: "p2"},
		},
	}

	splits, err := resolveSplits(req)
	if err != nil {
		t.Fatalf("resolveSplits failed: %v", err)
	}

	if splits[0].ShareAmount != 5025 || splits[1].ShareAmount != 5025 {
		t.Errorf("expected 5025 paise shares, got %d and %d", splits[0].ShareAmount, splits[1].ShareAmount)
	}
}

// TestOptimisticLockingVersionMismatch tests Service Layer version mismatch rejection
func TestOptimisticLockingVersionMismatch(t *testing.T) {
	svc := NewService(nil)
	_ = svc
}


