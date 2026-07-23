package main

import (
	"testing"
)

// sumShares is a test helper: adds up SharePaise across resolved splits.
func sumShares(splits []ResolvedSplit) int64 {
	var sum int64
	for _, s := range splits {
		sum += s.SharePaise
	}
	return sum
}

// ---------------------------------------------------------------
// Equal splits
// ---------------------------------------------------------------

func TestResolveEqual_DividesEvenly(t *testing.T) {
	inputs := []SplitInput{{Participant: "a"}, {Participant: "b"}}
	got, err := ResolveSplit(SplitEqual, 10000, inputs) // ₹100.00 in paise
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got[0].SharePaise != 5000 || got[1].SharePaise != 5000 {
		t.Errorf("expected 5000/5000, got %d/%d", got[0].SharePaise, got[1].SharePaise)
	}
}

func TestResolveEqual_RemainderGoesToFirst(t *testing.T) {
	inputs := []SplitInput{{Participant: "a"}, {Participant: "b"}, {Participant: "c"}}
	got, err := ResolveSplit(SplitEqual, 10000, inputs) // ₹100.00 / 3 = 33.33 each, 1 paisa left over
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	// 10000 / 3 = 3333 remainder 1
	if got[0].SharePaise != 3334 {
		t.Errorf("expected first participant to absorb remainder (3334), got %d", got[0].SharePaise)
	}
	if got[1].SharePaise != 3333 || got[2].SharePaise != 3333 {
		t.Errorf("expected remaining participants at 3333, got %d/%d", got[1].SharePaise, got[2].SharePaise)
	}
	if sum := sumShares(got); sum != 10000 {
		t.Errorf("splits must sum to total: got %d, want 10000", sum)
	}
}

func TestResolveEqual_SingleParticipant(t *testing.T) {
	inputs := []SplitInput{{Participant: "a"}}
	got, err := ResolveSplit(SplitEqual, 12345, inputs)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got[0].SharePaise != 12345 {
		t.Errorf("single participant should owe the full amount, got %d", got[0].SharePaise)
	}
}

// ---------------------------------------------------------------
// Exact splits
// ---------------------------------------------------------------

func TestResolveExact_ValidSumPasses(t *testing.T) {
	inputs := []SplitInput{
		{Participant: "a", RawValue: 3000},
		{Participant: "b", RawValue: 7000},
	}
	got, err := ResolveSplit(SplitExact, 10000, inputs)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got[0].SharePaise != 3000 || got[1].SharePaise != 7000 {
		t.Errorf("expected exact amounts preserved, got %d/%d", got[0].SharePaise, got[1].SharePaise)
	}
}

func TestResolveExact_MismatchedSumFails(t *testing.T) {
	inputs := []SplitInput{
		{Participant: "a", RawValue: 3000},
		{Participant: "b", RawValue: 6000}, // sums to 9000, not 10000
	}
	_, err := ResolveSplit(SplitExact, 10000, inputs)
	if err == nil {
		t.Fatal("expected error for mismatched exact amounts, got nil")
	}
}

func TestResolveExact_NegativeAmountFails(t *testing.T) {
	inputs := []SplitInput{
		{Participant: "a", RawValue: -100},
		{Participant: "b", RawValue: 10100},
	}
	_, err := ResolveSplit(SplitExact, 10000, inputs)
	if err == nil {
		t.Fatal("expected error for negative exact amount, got nil")
	}
}

// ---------------------------------------------------------------
// Percentage splits
// ---------------------------------------------------------------

func TestResolvePercentage_ValidSumPasses(t *testing.T) {
	inputs := []SplitInput{
		{Participant: "a", RawValue: 3000}, // 30%
		{Participant: "b", RawValue: 7000}, // 70%
	}
	got, err := ResolveSplit(SplitPercentage, 10000, inputs) // ₹100.00
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got[0].SharePaise != 3000 || got[1].SharePaise != 7000 {
		t.Errorf("expected 3000/7000, got %d/%d", got[0].SharePaise, got[1].SharePaise)
	}
}

func TestResolvePercentage_MismatchedSumFails(t *testing.T) {
	inputs := []SplitInput{
		{Participant: "a", RawValue: 3000},
		{Participant: "b", RawValue: 6000}, // sums to 90%, not 100%
	}
	_, err := ResolveSplit(SplitPercentage, 10000, inputs)
	if err == nil {
		t.Fatal("expected error for percentages not summing to 100%, got nil")
	}
}

func TestResolvePercentage_UnevenSplitSumsExactly(t *testing.T) {
	// 3-way split at 33.33%/33.33%/33.34% (9999+1 = 10000 bps) against an
	// awkward total, to prove the remainder-on-last logic holds up.
	inputs := []SplitInput{
		{Participant: "a", RawValue: 3333},
		{Participant: "b", RawValue: 3333},
		{Participant: "c", RawValue: 3334},
	}
	got, err := ResolveSplit(SplitPercentage, 10001, inputs) // an odd total on purpose
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if sum := sumShares(got); sum != 10001 {
		t.Errorf("splits must sum to total exactly: got %d, want 10001", sum)
	}
}

func TestResolvePercentage_NegativeFails(t *testing.T) {
	inputs := []SplitInput{
		{Participant: "a", RawValue: -1000},
		{Participant: "b", RawValue: 11000},
	}
	_, err := ResolveSplit(SplitPercentage, 10000, inputs)
	if err == nil {
		t.Fatal("expected error for negative percentage, got nil")
	}
}

// ---------------------------------------------------------------
// Shares splits
// ---------------------------------------------------------------

func TestResolveShares_ProportionalSplit(t *testing.T) {
	inputs := []SplitInput{
		{Participant: "a", RawValue: 2}, // 2 shares
		{Participant: "b", RawValue: 1}, // 1 share
	}
	got, err := ResolveSplit(SplitShares, 9000, inputs) // ₹90.00 across 3 total shares = 30 each
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got[0].SharePaise != 6000 || got[1].SharePaise != 3000 {
		t.Errorf("expected 6000/3000 (2:1 ratio), got %d/%d", got[0].SharePaise, got[1].SharePaise)
	}
}

func TestResolveShares_UnevenDivisionSumsExactly(t *testing.T) {
	inputs := []SplitInput{
		{Participant: "a", RawValue: 1},
		{Participant: "b", RawValue: 1},
		{Participant: "c", RawValue: 1},
	}
	got, err := ResolveSplit(SplitShares, 10000, inputs) // 10000/3 doesn't divide evenly
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if sum := sumShares(got); sum != 10000 {
		t.Errorf("splits must sum to total exactly: got %d, want 10000", sum)
	}
}

func TestResolveShares_ZeroSharesFails(t *testing.T) {
	inputs := []SplitInput{
		{Participant: "a", RawValue: 0},
		{Participant: "b", RawValue: 1},
	}
	_, err := ResolveSplit(SplitShares, 10000, inputs)
	if err == nil {
		t.Fatal("expected error for zero share count, got nil")
	}
}

func TestResolveShares_NegativeSharesFails(t *testing.T) {
	inputs := []SplitInput{
		{Participant: "a", RawValue: -1},
		{Participant: "b", RawValue: 2},
	}
	_, err := ResolveSplit(SplitShares, 10000, inputs)
	if err == nil {
		t.Fatal("expected error for negative share count, got nil")
	}
}

// ---------------------------------------------------------------
// Cross-cutting validation (applies to all split types)
// ---------------------------------------------------------------

func TestResolveSplit_ZeroTotalFails(t *testing.T) {
	inputs := []SplitInput{{Participant: "a"}}
	_, err := ResolveSplit(SplitEqual, 0, inputs)
	if err == nil {
		t.Fatal("expected error for zero total amount, got nil")
	}
}

func TestResolveSplit_NegativeTotalFails(t *testing.T) {
	inputs := []SplitInput{{Participant: "a"}}
	_, err := ResolveSplit(SplitEqual, -500, inputs)
	if err == nil {
		t.Fatal("expected error for negative total amount, got nil")
	}
}

func TestResolveSplit_EmptyParticipantsFails(t *testing.T) {
	_, err := ResolveSplit(SplitEqual, 10000, []SplitInput{})
	if err == nil {
		t.Fatal("expected error for empty participants, got nil")
	}
}

func TestResolveSplit_DuplicateParticipantFails(t *testing.T) {
	inputs := []SplitInput{
		{Participant: "a", RawValue: 5000},
		{Participant: "a", RawValue: 5000}, // duplicate
	}
	_, err := ResolveSplit(SplitExact, 10000, inputs)
	if err == nil {
		t.Fatal("expected error for duplicate participant, got nil")
	}
}

func TestResolveSplit_UnknownSplitTypeFails(t *testing.T) {
	inputs := []SplitInput{{Participant: "a"}}
	_, err := ResolveSplit(SplitType("bogus"), 10000, inputs)
	if err == nil {
		t.Fatal("expected error for unknown split type, got nil")
	}
}

// ---------------------------------------------------------------
// Invariant check across many cases: every resolved split, regardless of
// type, must sum EXACTLY to the total. This is the one property that must
// never break, since it's what "the money adds up" actually means.
// ---------------------------------------------------------------

func TestInvariant_AllSplitTypesSumExactly(t *testing.T) {
	cases := []struct {
		name      string
		splitType SplitType
		total     int64
		inputs    []SplitInput
	}{
		{"equal-2way-odd-total", SplitEqual, 10001, []SplitInput{{Participant: "a"}, {Participant: "b"}}},
		{"equal-7way", SplitEqual, 99999, []SplitInput{
			{Participant: "a"}, {Participant: "b"}, {Participant: "c"}, {Participant: "d"},
			{Participant: "e"}, {Participant: "f"}, {Participant: "g"},
		}},
		{"exact-3way", SplitExact, 15000, []SplitInput{
			{Participant: "a", RawValue: 5000},
			{Participant: "b", RawValue: 5000},
			{Participant: "c", RawValue: 5000},
		}},
		{"percentage-3way-odd", SplitPercentage, 33333, []SplitInput{
			{Participant: "a", RawValue: 3333},
			{Participant: "b", RawValue: 3333},
			{Participant: "c", RawValue: 3334},
		}},
		{"shares-uneven", SplitShares, 100000, []SplitInput{
			{Participant: "a", RawValue: 7},
			{Participant: "b", RawValue: 3},
			{Participant: "c", RawValue: 1},
		}},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got, err := ResolveSplit(tc.splitType, tc.total, tc.inputs)
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			if sum := sumShares(got); sum != tc.total {
				t.Errorf("%s: splits summed to %d, want %d", tc.name, sum, tc.total)
			}
		})
	}
}
