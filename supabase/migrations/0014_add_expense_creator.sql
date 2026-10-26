-- Add created_by to public.expenses so the original expense creator is tracked
-- independently from payer_id when a user records an expense paid by another participant.
ALTER TABLE public.expenses
  ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES public.participants(id);

-- Backfill existing expenses so historical records treat their payer as the creator
UPDATE public.expenses
  SET created_by = payer_id
  WHERE created_by IS NULL;

-- Index created_by for fast creator queries
CREATE INDEX IF NOT EXISTS idx_expenses_created_by ON public.expenses(created_by);
