-- Migration: Add idempotency_key and version columns to expenses
-- Required by apps/backend/expenses.go which references these columns
-- Without this, POST /api/v1/expenses returns 500 with column-not-found error

ALTER TABLE public.expenses
  ADD COLUMN IF NOT EXISTS idempotency_key text,
  ADD COLUMN IF NOT EXISTS version integer NOT NULL DEFAULT 1;

ALTER TABLE public.expenses
  ADD CONSTRAINT uq_expenses_idempotency_key UNIQUE (idempotency_key);
