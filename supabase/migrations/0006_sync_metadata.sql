-- Migration: Add sync metadata columns and enable client-generated IDs
--
-- 1. Adds updated_at, deleted_at to all entities for offline-first sync
-- 2. Adds version to lists and contacts for optimistic concurrency
-- 3. Makes participant_id defaults use gen_random_uuid() so clients can
--    supply UUIDs (or let the DB generate them) for profiles and contacts

-- ============================================================
-- participants
-- ============================================================
ALTER TABLE public.participants
  ADD COLUMN IF NOT EXISTS updated_at timestamptz,
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

-- ============================================================
-- profiles
-- ============================================================
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS updated_at timestamptz,
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

ALTER TABLE public.profiles
  ALTER COLUMN participant_id SET DEFAULT gen_random_uuid();

-- ============================================================
-- contacts
-- ============================================================
ALTER TABLE public.contacts
  ADD COLUMN IF NOT EXISTS updated_at timestamptz,
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz,
  ADD COLUMN IF NOT EXISTS version integer NOT NULL DEFAULT 1;

ALTER TABLE public.contacts
  ALTER COLUMN participant_id SET DEFAULT gen_random_uuid();

-- ============================================================
-- lists (collections)
-- ============================================================
ALTER TABLE public.lists
  ADD COLUMN IF NOT EXISTS updated_at timestamptz,
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz,
  ADD COLUMN IF NOT EXISTS version integer NOT NULL DEFAULT 1;

-- ============================================================
-- list_members
-- ============================================================
ALTER TABLE public.list_members
  ADD COLUMN IF NOT EXISTS updated_at timestamptz,
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

-- ============================================================
-- expenses
-- ============================================================
ALTER TABLE public.expenses
  ADD COLUMN IF NOT EXISTS updated_at timestamptz,
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

-- ============================================================
-- expense_splits
-- ============================================================
ALTER TABLE public.expense_splits
  ADD COLUMN IF NOT EXISTS updated_at timestamptz,
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

-- ============================================================
-- receipt_details
-- ============================================================
ALTER TABLE public.receipt_details
  ADD COLUMN IF NOT EXISTS updated_at timestamptz,
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

-- ============================================================
-- Update pairwise_balances view to exclude soft-deleted records
-- ============================================================
CREATE OR REPLACE VIEW public.pairwise_balances AS
select
  coalesce(from_contact.claimed_by_participant_id, es.participant_id) as from_participant,
  coalesce(to_contact.claimed_by_participant_id, e.payer_id) as to_participant,
  sum(es.share_amount) as amount_owed
from public.expense_splits es
join public.expenses e on e.id = es.expense_id
left join public.contacts from_contact on from_contact.participant_id = es.participant_id
left join public.contacts to_contact on to_contact.participant_id = e.payer_id
where coalesce(from_contact.claimed_by_participant_id, es.participant_id)
    != coalesce(to_contact.claimed_by_participant_id, e.payer_id)
  and e.deleted_at is null
  and es.deleted_at is null
group by
  coalesce(from_contact.claimed_by_participant_id, es.participant_id),
  coalesce(to_contact.claimed_by_participant_id, e.payer_id);
