# Settl Architecture & Integration Guidelines

This document details client-side requirements for Flutter application developers and production database/architecture specifications for the Settl backend.

---

## 1. Phone Number Normalization (E.164)
- **Requirement:** Phone numbers MUST be normalized to standard **E.164 format** (e.g. `+919876543210`) before sending to the backend or storing locally.
- **Flutter Implementation:** Use `phone_number` / `libphonenumber_plugin` to format input prior to storage or claiming:
  ```dart
  import 'package:phone_number/phone_number.dart';

  Future<String?> normalizePhone(String rawInput, String regionCode) async {
    final phoneNumberUtil = PhoneNumberUtil();
    bool isValid = await phoneNumberUtil.validate(rawInput, regionCode);
    if (!isValid) return null;
    final parsed = await phoneNumberUtil.parse(rawInput, regionCode);
    return parsed.e164; // returns "+91..."
  }
  ```

---

## 2. Monetary Representations (`amount_paise`)
- **Requirement:** Money values are stored and calculated in **int64 paise/minor units** (`1050` = ₹10.50).
- **Rule:** Amounts sent to and received from API endpoints use `amount_paise` integers.
- **Flutter Implementation:** 
  - Restrict input text fields using `FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))`.
  - Convert input to paise before sending: `final int amountPaise = (doubleVal * 100).round();`.

---

## 3. Idempotency Key & Duplicate Submission Prevention
- **Requirement:** To avoid duplicate expense creation during double-taps or offline retries, every expense creation request MUST include a unique idempotency key.
- **Header / Payload:** Include `Idempotency-Key: <UUIDv4>` header or `idempotency_key` in POST requests. Enforced atomically via PostgreSQL `INSERT ... ON CONFLICT (idempotency_key) DO NOTHING`.

---

## 4. Audit History & Soft Deletes
- **Soft Deletes:** Financial records use `deleted_at TIMESTAMP WITH TIME ZONE` instead of hard `DELETE` statements to preserve accounting history, auditability, and allow "undo" actions.
- **Audit Fields:** Expenses and splits track `created_by`, `updated_by`, `created_at`, and `updated_at`.
- **Expense History Table:** Crucial expense edits write an immutable snapshot to `expense_history (expense_id, modified_by, version, old_state, new_state, created_at)` to answer "Who changed this expense?".

---

## 5. Required Database Indexes
For optimal query performance at scale, the database schema maintains the following indexes:
- `expenses(list_id)`
- `expenses(payer_id)`
- `expenses(created_at DESC)`
- `expenses(idempotency_key) WHERE idempotency_key IS NOT NULL` (UNIQUE index)
- `expense_splits(expense_id, participant_id)`
- `contacts(phone_number)`
- `profiles(user_id)`
- `list_members(list_id, participant_id)`

---

## 6. Offline Sync & Tombstones
- **Sync Queue:** The mobile client maintains a local SQLite/Isar queue for pending operations (`CREATE_EXPENSE`, `UPDATE_EXPENSE`, `DELETE_EXPENSE`).
- **Tombstones:** Deleted expenses are synced with `deleted_at` tombstones so offline devices can reconcile removed items without orphaned records.
- **Conflict Resolution (OCC):**
  1. Server rejects stale edits with `409 Conflict` if client version doesn't match current DB version.
  2. Mobile client prompts user with a conflict resolution modal (Keep Local / Keep Server / Manual Merge).

