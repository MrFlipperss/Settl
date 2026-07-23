package main

import (
	"context"
	"errors"
	"fmt"
	"time"
)

type Service struct {
	repo *DBQueries
}

func NewService(repo *DBQueries) *Service {
	return &Service{repo: repo}
}

// CreateExpense handles validation, authorization, dynamic split calculation, and DB persistence.
func (s *Service) CreateExpense(ctx context.Context, callerPID string, req CreateExpenseRequest) (*Expense, error) {
	if req.PayerID == "" || req.Amount <= 0 || len(req.Splits) == 0 {
		return nil, errors.New("payer_id, amount, and splits are required")
	}

	if !validateMaxDecimals(req.Amount, 2) {
		return nil, errors.New("amount cannot have more than 2 decimal places")
	}

	if req.GroupID != nil && *req.GroupID != "" {
		inGroup, err := s.repo.IsUserInGroup(ctx, *req.GroupID, callerPID)
		if err != nil || !inGroup {
			return nil, errors.New("user does not belong to group")
		}
	}

	splits, err := resolveSplits(req)
	if err != nil {
		return nil, err
	}

	return s.repo.CreateExpense(ctx, req, splits)
}

// GetExpense handles membership/participant authorization checks.
func (s *Service) GetExpense(ctx context.Context, callerPID, id string) (*Expense, error) {
	expense, err := s.repo.GetExpense(ctx, id)
	if err != nil || expense == nil {
		return expense, err
	}

	isAuthorized := expense.PayerID == callerPID
	if !isAuthorized {
		for _, sp := range expense.Splits {
			if sp.ParticipantID == callerPID {
				isAuthorized = true
				break
			}
		}
	}

	if !isAuthorized && expense.ListID != nil && *expense.ListID != "" {
		inGroup, err := s.repo.IsUserInGroup(ctx, *expense.ListID, callerPID)
		if err == nil && inGroup {
			isAuthorized = true
		}
	}

	if !isAuthorized {
		return nil, errors.New("access denied: user does not belong to this expense or group")
	}

	return expense, nil
}

// UpdateExpense handles optimistic concurrency version checks and dynamic split updates.
func (s *Service) UpdateExpense(ctx context.Context, callerPID, id string, req CreateExpenseRequest, expectedVersion int) (*Expense, error) {
	existing, err := s.repo.GetExpense(ctx, id)
	if err != nil || existing == nil {
		return nil, errors.New("expense not found")
	}

	if existing.PayerID != callerPID {
		return nil, errors.New("only payer can edit expense")
	}

	if expectedVersion > 0 && existing.Version != expectedVersion {
		return nil, fmt.Errorf("conflict: expense version mismatch (current: %d, provided: %d)", existing.Version, expectedVersion)
	}

	if !validateMaxDecimals(req.Amount, 2) {
		return nil, errors.New("amount cannot have more than 2 decimal places")
	}

	splits, err := resolveSplits(req)
	if err != nil {
		return nil, err
	}

	return s.repo.UpdateExpense(ctx, id, req, splits, expectedVersion)
}

// DeleteExpense checks ownership and safe cascade deletion.
func (s *Service) DeleteExpense(ctx context.Context, callerPID, id string) error {
	existing, err := s.repo.GetExpense(ctx, id)
	if err != nil || existing == nil {
		return errors.New("expense not found")
	}

	if existing.PayerID != callerPID {
		return errors.New("only payer can delete expense")
	}

	return s.repo.DeleteExpense(ctx, id)
}

// ListExpenses returns authorized expense history.
func (s *Service) ListExpenses(ctx context.Context, callerPID string, groupID *string, from, to *time.Time) ([]Expense, error) {
	return s.repo.ListExpenses(ctx, groupID, from, to, callerPID)
}
