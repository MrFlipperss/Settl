-- Settl: add receipt_details (text-only, no images)
--
-- The receipt IMAGE never leaves the payer's device — no file/image storage
-- on the server, per the offline-first philosophy. But the OCR-extracted
-- TEXT fields are small enough to sync, and other split participants have a
-- legitimate reason to see them (it's their money too) even though they'll
-- never see the original photo. So: one row per expense, text fields only.

create table public.receipt_details (
  expense_id uuid primary key references public.expenses(id) on delete cascade,
  merchant text,
  ocr_total numeric(12,2),
  ocr_date date,
  -- Free-form line items as text, e.g. "2x Butter Chicken - 450".
  -- Kept as a simple text array rather than a normalized table for now —
  -- line-item splitting is a v2 feature per the product spec; this just
  -- needs to be readable, not queryable per-item, at this stage.
  line_items text[],
  created_by uuid not null references public.profiles(participant_id),
  created_at timestamptz not null default now()
);

alter table public.receipt_details enable row level security;

create policy "expense participants can view receipt details"
  on public.receipt_details for select
  using (
    exists (
      select 1 from public.profiles p
      where p.user_id = auth.uid()
      and (
        p.participant_id in (
          select payer_id from public.expenses where id = receipt_details.expense_id
        )
        or p.participant_id in (
          select participant_id from public.expense_splits where expense_id = receipt_details.expense_id
        )
      )
    )
  );

-- Note: INSERT/UPDATE intentionally omitted — writes go through the Go
-- backend (service role key), same as expenses/splits/contacts.
