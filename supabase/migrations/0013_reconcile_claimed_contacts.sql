-- Migration 0013: Reconcile claimed contacts and collection memberships
--
-- Preserves all historical financial records and participant IDs while:
-- 1. Reconciling list_members for contacts that were claimed by registered accounts.
-- 2. Soft-deleting redundant self-contacts created by users for their own phone numbers.

-- Reconcile list_members for any contacts already claimed by a registered profile
INSERT INTO public.list_members (list_id, participant_id, updated_at)
SELECT lm.list_id, c.claimed_by_participant_id, NOW()
FROM public.list_members lm
JOIN public.contacts c ON c.participant_id = lm.participant_id
WHERE c.claimed_by_participant_id IS NOT NULL
ON CONFLICT (list_id, participant_id) DO NOTHING;

DELETE FROM public.list_members lm
USING public.contacts c
WHERE lm.participant_id = c.participant_id
  AND c.claimed_by_participant_id IS NOT NULL;

-- Soft-delete redundant self-contacts where a user added themselves
UPDATE public.contacts
SET deleted_at = NOW()
WHERE claimed_by_participant_id IS NOT NULL
  AND claimed_by_participant_id = created_by
  AND deleted_at IS NULL;
