-- Migration: 0015_settlement_permissions.sql
-- Allow either participant in an outstanding balance to record a settlement.
-- The person who owes money can record they have paid, and the person who is owed
-- money can record that they have received payment.

CREATE POLICY "participants can insert settlements"
  ON public.settlements FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.participant_id IN (settlements.payer_participant_id, settlements.payee_participant_id)
        AND p.user_id = auth.uid()
    )
  );
