-- In-app notifications for shared expense activity.
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_participant_id uuid NOT NULL REFERENCES public.participants(id) ON DELETE CASCADE,
  actor_participant_id uuid NOT NULL REFERENCES public.participants(id) ON DELETE CASCADE,
  expense_id uuid REFERENCES public.expenses(id) ON DELETE CASCADE,
  contact_id uuid REFERENCES public.contacts(participant_id) ON DELETE CASCADE,
  type text NOT NULL,
  title text NOT NULL,
  body text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  read_at timestamptz,
  CHECK (expense_id IS NOT NULL OR contact_id IS NOT NULL)
);

CREATE UNIQUE INDEX IF NOT EXISTS notifications_expense_unique_idx
  ON public.notifications (recipient_participant_id, expense_id, type)
  WHERE expense_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS notifications_contact_unique_idx
  ON public.notifications (recipient_participant_id, contact_id, type)
  WHERE contact_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS notifications_recipient_created_idx
  ON public.notifications (recipient_participant_id, created_at DESC);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users can read notifications for their participant"
  ON public.notifications FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.participant_id = notifications.recipient_participant_id
        AND p.user_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1
      FROM public.contacts c
      JOIN public.profiles p ON p.participant_id = c.claimed_by_participant_id
      WHERE c.participant_id = notifications.recipient_participant_id
        AND p.user_id = auth.uid()
    )
  );

CREATE POLICY "users can mark their notifications read"
  ON public.notifications FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.participant_id = notifications.recipient_participant_id
        AND p.user_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1
      FROM public.contacts c
      JOIN public.profiles p ON p.participant_id = c.claimed_by_participant_id
      WHERE c.participant_id = notifications.recipient_participant_id
        AND p.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.participant_id = notifications.recipient_participant_id
        AND p.user_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1
      FROM public.contacts c
      JOIN public.profiles p ON p.participant_id = c.claimed_by_participant_id
      WHERE c.participant_id = notifications.recipient_participant_id
        AND p.user_id = auth.uid()
    )
  );
