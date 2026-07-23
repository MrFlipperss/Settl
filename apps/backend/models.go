package main

import "time"

type Participant struct {
	ID   string `json:"id"`
	Kind string `json:"kind"`
}

type Profile struct {
	ParticipantID string    `json:"participant_id"`
	UserID        string    `json:"user_id"`
	DisplayName   string    `json:"display_name"`
	PhoneNumber   *string   `json:"phone_number"`
	UPIID         *string   `json:"upi_id"`
	CreatedAt     time.Time `json:"created_at"`
}

type Contact struct {
	ParticipantID          string    `json:"participant_id"`
	DisplayName            string    `json:"display_name"`
	PhoneNumber            string    `json:"phone_number"`
	CreatedBy              string    `json:"created_by"`
	ClaimedByParticipantID *string   `json:"claimed_by_participant_id"`
	CreatedAt              time.Time `json:"created_at"`
}

type List struct {
	ID            string    `json:"id"`
	AccountNumber string    `json:"account_number"`
	Name          string    `json:"name"`
	CreatedBy     string    `json:"created_by"`
	CreatedAt     time.Time `json:"created_at"`
	MemberCount   int       `json:"member_count"`
}

type ListMember struct {
	ListID        string    `json:"list_id"`
	ParticipantID string    `json:"participant_id"`
	AddedAt       time.Time `json:"added_at"`
}

type Expense struct {
	ID        string    `json:"id"`
	ListID    *string   `json:"group_id"`
	PayerID   string    `json:"payer_id"`
	Amount    int64     `json:"amount_paise"` // Stored and calculated as int64 paise
	Category  string    `json:"category"`
	Note      *string   `json:"note,omitempty"`
	SplitType string    `json:"split_type"`
	Version   int       `json:"version"` // Optimistic locking version
	CreatedAt time.Time `json:"timestamp"`
	Splits    []Split   `json:"splits"`
}

type Split struct {
	ID            string `json:"id,omitempty"`
	ExpenseID     string `json:"-"`
	ParticipantID string `json:"user_id"`
	ShareAmount   int64  `json:"share_amount_paise"` // Stored as int64 paise
	RawInput      *int64 `json:"-"`
}

type ReceiptDetail struct {
	ExpenseID string    `json:"expense_id"`
	Merchant  *string   `json:"merchant"`
	OCRTotal  *int64    `json:"ocr_total_paise,omitempty"`
	OCRDate   *string   `json:"ocr_date"`
	LineItems []string  `json:"line_items"`
	CreatedBy string    `json:"created_by"`
	CreatedAt time.Time `json:"created_at"`
}

type BalanceEntry struct {
	UserID    string  `json:"user_id"`
	UserName  string  `json:"user_name"`
	GroupID   *string `json:"group_id,omitempty"`
	GroupName *string `json:"group_name,omitempty"`
	Amount    int64   `json:"amount_paise"`
	Currency  string  `json:"currency"`
}

type BalancesResponse struct {
	TotalOwed  int64          `json:"total_owed_paise"`
	TotalOwing int64          `json:"total_owing_paise"`
	Net        int64          `json:"net_paise"`
	Breakdown  []BalanceEntry `json:"breakdown"`
}

type CreateGroupRequest struct {
	Name     string  `json:"name"`
	Currency *string `json:"currency"`
}

type AddMemberRequest struct {
	UserID string `json:"user_id"`
}

type CreateExpenseRequest struct {
	GroupID        *string           `json:"group_id"`
	PayerID        string            `json:"payer_id"`
	Amount         float64           `json:"amount"`
	SplitType      string            `json:"split_type"` // "equal"|"exact"|"percentage"|"shares" — applies to all splits
	Category       *string           `json:"category"`
	Note           *string           `json:"note"`
	IdempotencyKey *string           `json:"idempotency_key,omitempty"`
	Timestamp      *time.Time        `json:"timestamp"`
	Splits         []CreateSplitItem `json:"splits"`
}

type CreateSplitItem struct {
	UserID      string   `json:"user_id"`
	ExactAmount *float64 `json:"exact_amount"` // SplitExact: this participant's share in ₹
	Percentage  *float64 `json:"percentage"`   // SplitPercentage: 0–100 (e.g. 33.33)
	ShareCount  *int     `json:"share_count"`  // SplitShares: positive integer weight
}

type CreateContactRequest struct {
	DisplayName string `json:"display_name"`
	PhoneNumber string `json:"phone_number"`
}

type ClaimContactsRequest struct {
	PhoneNumber string `json:"phone_number"`
}

type CreateReceiptRequest struct {
	Merchant  *string  `json:"merchant"`
	OCRTotal  *float64 `json:"ocr_total"`
	OCRDate   *string  `json:"ocr_date"`
	LineItems []string `json:"line_items"`
}

type HealthResponse struct {
	Status  string `json:"status"`
	Service string `json:"service"`
}

type ErrorResponse struct {
	Error string `json:"error"`
}
