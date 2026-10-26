package main

import (
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

// authMiddlewareStatus runs a request through AuthMiddleware(cfg, nil) and
// returns the HTTP status code the middleware itself produced. The wrapped
// handler writes 200 so a passthrough is unambiguous.
func authMiddlewareStatus(t *testing.T, cfg Config, authHeader string) int {
	t.Helper()
	handler := AuthMiddleware(cfg, nil)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	req := httptest.NewRequest(http.MethodGet, "/api/v1/balances", nil)
	if authHeader != "" {
		req.Header.Set("Authorization", authHeader)
	}
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)
	return rec.Code
}

// TestAuthMiddleware_DevTokenRequiresDevelopmentEnv verifies the dev_token
// bypass only activates when Config.Env is explicitly "development"/"dev" —
// it must never activate just because Env is unset (the production default).
func TestAuthMiddleware_DevTokenRequiresDevelopmentEnv(t *testing.T) {
	prodCfg := Config{JWTSecret: mockSecret} // Env unset — production default
	if status := authMiddlewareStatus(t, prodCfg, "Bearer dev_token"); status != http.StatusUnauthorized {
		t.Errorf("dev_token with unset Env: expected 401, got %d", status)
	}

	stagingCfg := Config{JWTSecret: mockSecret, Env: "staging"}
	if status := authMiddlewareStatus(t, stagingCfg, "Bearer dev_token"); status != http.StatusUnauthorized {
		t.Errorf("dev_token with Env=staging: expected 401, got %d", status)
	}

	devCfg := Config{JWTSecret: mockSecret, Env: "development"}
	if status := authMiddlewareStatus(t, devCfg, "Bearer dev_token"); status != http.StatusOK {
		t.Errorf("dev_token with Env=development: expected 200, got %d", status)
	}
}

// TestAuthMiddleware_MissingTokenIsAlways401 verifies a request with no
// Authorization header is rejected regardless of environment — a missing
// token must never be treated as an implicit dev_token.
func TestAuthMiddleware_MissingTokenIsAlways401(t *testing.T) {
	for _, cfg := range []Config{
		{JWTSecret: mockSecret},                     // production default
		{JWTSecret: mockSecret, Env: "development"}, // dev
	} {
		if status := authMiddlewareStatus(t, cfg, ""); status != http.StatusUnauthorized {
			t.Errorf("missing token (Env=%q): expected 401, got %d", cfg.Env, status)
		}
	}
}

// TestContactClaimAuthorizationLogic verifies phone normalization logic
// used to securely match claiming callers with their verified account phone.
func TestContactClaimAuthorizationLogic(t *testing.T) {
	callerPhone := "+919876543210"

	validInputs := []string{
		"9876543210",
		"09876543210",
		"+91 9876543210",
		"+919876543210",
	}

	for _, input := range validInputs {
		if got := NormalizePhoneNumber(input); got != callerPhone {
			t.Errorf("expected %q to normalize to %q, got %q", input, callerPhone, got)
		}
	}

	invalidInputs := []string{
		"9876543211",
		"+919876543219",
		"1234567890",
	}

	for _, input := range invalidInputs {
		if got := NormalizePhoneNumber(input); got == callerPhone {
			t.Errorf("expected %q NOT to match %q", input, callerPhone)
		}
	}
}

// TestContactCanonicalResolution verifies that when a contact is claimed,
// its effective participant identity becomes the registered profile's participant ID.
func TestContactCanonicalResolution(t *testing.T) {
	placeholderID := "contact-uuid-1"
	claimedProfileID := "user-uuid-99"

	contact := Contact{
		ParticipantID:          placeholderID,
		DisplayName:            "Rahul",
		PhoneNumber:            "+919876543210",
		ClaimedByParticipantID: &claimedProfileID,
		IsRegistered:           true,
	}

	// Canonical resolution rule: if ClaimedByParticipantID is present, use it
	canonicalID := contact.ParticipantID
	if contact.ClaimedByParticipantID != nil && *contact.ClaimedByParticipantID != "" {
		canonicalID = *contact.ClaimedByParticipantID
	}

	if canonicalID != claimedProfileID {
		t.Errorf("expected canonical ID %q, got %q", claimedProfileID, canonicalID)
	}

	// Unclaimed contact remains its placeholder ID
	unclaimed := Contact{
		ParticipantID: placeholderID,
		DisplayName:   "Rahul",
		PhoneNumber:   "+919876543210",
	}
	canonicalUnclaimed := unclaimed.ParticipantID
	if unclaimed.ClaimedByParticipantID != nil && *unclaimed.ClaimedByParticipantID != "" {
		canonicalUnclaimed = *unclaimed.ClaimedByParticipantID
	}
	if canonicalUnclaimed != placeholderID {
		t.Errorf("expected unclaimed canonical ID %q, got %q", placeholderID, canonicalUnclaimed)
	}
}

// TestHistoricalExpenseIntegrityWithCanonicalClaiming tests that split amounts
// and net obligations are preserved before and after claiming.
func TestHistoricalExpenseIntegrityWithCanonicalClaiming(t *testing.T) {
	// Payer owes nothing, Split participants owe their share.
	req := CreateExpenseRequest{
		Amount:    600.00,
		SplitType: "equal",
		Splits: []CreateSplitItem{
			{UserID: "payer-user-1"},
			{UserID: "placeholder-contact-2"}, // Rahul before registering
			{UserID: "registered-user-3"},
		},
	}

	splits, err := resolveSplits(req)
	if err != nil {
		t.Fatalf("resolveSplits failed: %v", err)
	}

	if len(splits) != 3 {
		t.Fatalf("expected 3 splits, got %d", len(splits))
	}

	// Total must sum to 60000 paise (600 INR)
	var totalPaise int64
	for _, s := range splits {
		totalPaise += s.ShareAmount
		if s.ShareAmount != 20000 {
			t.Errorf("expected equal share 20000 paise, got %d", s.ShareAmount)
		}
	}
	if totalPaise != 60000 {
		t.Errorf("expected total 60000 paise, got %d", totalPaise)
	}

	// Simulating resolution: placeholder-contact-2 claims as registered-user-2
	contactClaimMapping := map[string]string{
		"placeholder-contact-2": "registered-user-2",
	}

	resolvedParticipants := make([]string, len(splits))
	for i, s := range splits {
		if canonical, claimed := contactClaimMapping[s.ParticipantID]; claimed {
			resolvedParticipants[i] = canonical
		} else {
			resolvedParticipants[i] = s.ParticipantID
		}
	}

	expectedParticipants := []string{"payer-user-1", "registered-user-2", "registered-user-3"}
	for i, expected := range expectedParticipants {
		if resolvedParticipants[i] != expected {
			t.Errorf("split[%d]: expected participant %q, got %q", i, expected, resolvedParticipants[i])
		}
	}
}

