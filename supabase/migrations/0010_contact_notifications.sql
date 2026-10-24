-- Allow notifications to be queued for contacts before they create an account.
ALTER TABLE public.notifications
  ALTER COLUMN expense_id DROP NOT NULL;

ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS contact_id uuid REFERENCES public.contacts(participant_id) ON DELETE CASCADE;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.notifications'::regclass
      AND conname = 'notifications_target_required'
  ) THEN
    ALTER TABLE public.notifications
      ADD CONSTRAINT notifications_target_required
      CHECK (expense_id IS NOT NULL OR contact_id IS NOT NULL);
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS notifications_contact_unique_idx
  ON public.notifications (recipient_participant_id, contact_id, type)
  WHERE contact_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS notifications_expense_unique_idx
  ON public.notifications (recipient_participant_id, expense_id, type)
  WHERE expense_id IS NOT NULL;
