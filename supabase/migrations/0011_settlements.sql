-- Track user-reported payments between participants. Registered payees
-- confirm receipt before the payment changes the pairwise ledger.
CREATE TABLE IF NOT EXISTS public.settlements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  payer_participant_id uuid NOT NULL REFERENCES public.participants(id) ON DELETE CASCADE,
  payee_participant_id uuid NOT NULL REFERENCES public.participants(id) ON DELETE CASCADE,
  amount numeric(12, 2) NOT NULL CHECK (amount > 0),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'declined')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  confirmed_at timestamptz,
  CHECK (payer_participant_id <> payee_participant_id)
);

CREATE INDEX IF NOT EXISTS settlements_payer_created_idx
  ON public.settlements (payer_participant_id, created_at DESC);
CREATE INDEX IF NOT EXISTS settlements_payee_created_idx
  ON public.settlements (payee_participant_id, created_at DESC);
CREATE INDEX IF NOT EXISTS settlements_status_idx
  ON public.settlements (status) WHERE status = 'pending';

ALTER TABLE public.settlements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users can read their settlements"
  ON public.settlements FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.participant_id IN (settlements.payer_participant_id, settlements.payee_participant_id)
        AND p.user_id = auth.uid()
    )
  );

CREATE POLICY "payees can confirm settlements"
  ON public.settlements FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.participant_id = settlements.payee_participant_id
        AND p.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.participant_id = settlements.payee_participant_id
        AND p.user_id = auth.uid()
    )
  );
