package main

import "fmt"

// SplitType is the strategy used to divide an expense among participants.
type SplitType string

const (
	SplitEqual      SplitType = "equal"
	SplitExact      SplitType = "exact"
	SplitPercentage SplitType = "percentage"
	SplitShares     SplitType = "shares"
)

// SplitInput is one participant's row in a split request.
//
//   - Participant: opaque string identifying the person (user ID, contact ID, etc.)
//   - RawValue:    interpretation depends on SplitType:
//     Equal      — ignored
//     Exact      — amount in paise they owe
//     Percentage — basis points (10000 bps = 100.00%)
//     Shares     — number of shares (positive integer)
type SplitInput struct {
	Participant string
	RawValue    int64
}

// ResolvedSplit is the output for a single participant after the split is
// calculated.  SharePaise is always a non-negative integer in paise (₹1 = 100
// paise) and the slice is guaranteed to sum exactly to the totalPaise passed
// into ResolveSplit.
type ResolvedSplit struct {
	Participant string
	SharePaise  int64
}

// ResolveSplit is the single entry point for all split calculations.
// It validates inputs, dispatches to the appropriate strategy, and guarantees
// that the returned shares sum exactly to totalPaise (no paise lost to
// rounding).
//
// totalPaise must be > 0.
// inputs must be non-empty and contain no duplicate Participant values.
func ResolveSplit(splitType SplitType, totalPaise int64, inputs []SplitInput) ([]ResolvedSplit, error) {
	// --- cross-cutting guard rails ---
	if totalPaise <= 0 {
		return nil, fmt.Errorf("splitcalc: totalPaise must be positive, got %d", totalPaise)
	}
	if len(inputs) == 0 {
		return nil, fmt.Errorf("splitcalc: inputs must not be empty")
	}
	seen := make(map[string]struct{}, len(inputs))
	for _, inp := range inputs {
		if _, dup := seen[inp.Participant]; dup {
			return nil, fmt.Errorf("splitcalc: duplicate participant %q", inp.Participant)
		}
		seen[inp.Participant] = struct{}{}
	}

	switch splitType {
	case SplitEqual:
		return resolveEqual(totalPaise, inputs)
	case SplitExact:
		return resolveExact(totalPaise, inputs)
	case SplitPercentage:
		return resolvePercentage(totalPaise, inputs)
	case SplitShares:
		return resolveShares(totalPaise, inputs)
	default:
		return nil, fmt.Errorf("splitcalc: unknown split type %q", splitType)
	}
}

// ---------------------------------------------------------------
// Equal — divide totalPaise as evenly as possible; any remainder
// paise (at most n-1) is added to the first participant.
// ---------------------------------------------------------------

func resolveEqual(totalPaise int64, inputs []SplitInput) ([]ResolvedSplit, error) {
	n := int64(len(inputs))
	base := totalPaise / n
	remainder := totalPaise % n

	results := make([]ResolvedSplit, len(inputs))
	for i, inp := range inputs {
		share := base
		if i == 0 {
			share += remainder // first participant absorbs all leftover paise
		}
		results[i] = ResolvedSplit{Participant: inp.Participant, SharePaise: share}
	}
	return results, nil
}

// ---------------------------------------------------------------
// Exact — each RawValue is already in paise; they must sum to
// totalPaise exactly and every value must be non-negative.
// ---------------------------------------------------------------

func resolveExact(totalPaise int64, inputs []SplitInput) ([]ResolvedSplit, error) {
	var sum int64
	for _, inp := range inputs {
		if inp.RawValue < 0 {
			return nil, fmt.Errorf("splitcalc: exact split amount for %q must be non-negative, got %d", inp.Participant, inp.RawValue)
		}
		sum += inp.RawValue
	}
	if sum != totalPaise {
		return nil, fmt.Errorf("splitcalc: exact amounts sum to %d paise but total is %d", sum, totalPaise)
	}

	results := make([]ResolvedSplit, len(inputs))
	for i, inp := range inputs {
		results[i] = ResolvedSplit{Participant: inp.Participant, SharePaise: inp.RawValue}
	}
	return results, nil
}

// ---------------------------------------------------------------
// Percentage — RawValue is in basis points (10000 bps = 100.00%).
// All values must be non-negative and must sum to exactly 10000.
// We derive paise amounts via integer multiplication, then assign
// any rounding remainder to the last participant.
// ---------------------------------------------------------------

const basisPointFull int64 = 10_000

func resolvePercentage(totalPaise int64, inputs []SplitInput) ([]ResolvedSplit, error) {
	var sumBps int64
	for _, inp := range inputs {
		if inp.RawValue < 0 {
			return nil, fmt.Errorf("splitcalc: percentage for %q must be non-negative, got %d bps", inp.Participant, inp.RawValue)
		}
		sumBps += inp.RawValue
	}
	if sumBps != basisPointFull {
		return nil, fmt.Errorf("splitcalc: percentages sum to %d bps, must equal %d (100%%)", sumBps, basisPointFull)
	}

	results := make([]ResolvedSplit, len(inputs))
	var allocated int64
	for i, inp := range inputs {
		var share int64
		if i == len(inputs)-1 {
			// Last participant gets whatever is left to guarantee the sum is exact.
			share = totalPaise - allocated
		} else {
			// Integer truncation; the small remainder is collected and assigned last.
			share = (totalPaise * inp.RawValue) / basisPointFull
			allocated += share
		}
		results[i] = ResolvedSplit{Participant: inp.Participant, SharePaise: share}
	}
	return results, nil
}

// ---------------------------------------------------------------
// Shares — RawValue is the number of shares owned by each
// participant (positive integer).  We compute per-share cost using
// integer division and assign the remainder to the first
// participant (consistent with Equal split behaviour).
// ---------------------------------------------------------------

func resolveShares(totalPaise int64, inputs []SplitInput) ([]ResolvedSplit, error) {
	var totalShares int64
	for _, inp := range inputs {
		if inp.RawValue <= 0 {
			return nil, fmt.Errorf("splitcalc: share count for %q must be positive, got %d", inp.Participant, inp.RawValue)
		}
		totalShares += inp.RawValue
	}

	results := make([]ResolvedSplit, len(inputs))
	var allocated int64
	for i, inp := range inputs {
		var share int64
		if i == len(inputs)-1 {
			// Last participant gets the remainder to guarantee exactness.
			share = totalPaise - allocated
		} else {
			share = (totalPaise * inp.RawValue) / totalShares
			allocated += share
		}
		results[i] = ResolvedSplit{Participant: inp.Participant, SharePaise: share}
	}
	return results, nil
}