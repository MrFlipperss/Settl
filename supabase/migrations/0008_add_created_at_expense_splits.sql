-- The backend includes split creation time in expense responses and writes it
-- when creating or replacing splits. The initial schema omitted this column.
ALTER TABLE public.expense_splits
  ADD COLUMN IF NOT EXISTS created_at timestamptz;

ALTER TABLE public.expense_splits
  ALTER COLUMN created_at SET DEFAULT now();

-- Preserve the parent expense's original timestamp for pre-existing splits.
UPDATE public.expense_splits AS split
SET created_at = expense.created_at
FROM public.expenses AS expense
WHERE split.expense_id = expense.id
  AND split.created_at IS NULL;

UPDATE public.expense_splits
SET created_at = now()
WHERE created_at IS NULL;

ALTER TABLE public.expense_splits
  ALTER COLUMN created_at SET NOT NULL;
