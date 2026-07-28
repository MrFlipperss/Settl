-- Migration: Add created_at to list_members
-- The 0006 migration added updated_at/deleted_at but the Go code
-- also writes created_at on INSERT. This column was missing.

ALTER TABLE public.list_members
  ADD COLUMN IF NOT EXISTS created_at timestamptz;

-- Backfill created_at for existing rows using a reasonable default
UPDATE public.list_members SET created_at = now() WHERE created_at IS NULL;

-- Make it NOT NULL going forward
ALTER TABLE public.list_members
  ALTER COLUMN created_at SET NOT NULL;
