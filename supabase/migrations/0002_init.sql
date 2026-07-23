-- Settl: server-side schema (v4)
--
-- PHILOSOPHY: offline-first. The server holds ONLY what must be shared or
-- reconciled across people: who owes whom. Everything device-personal and
-- reconstructable locally (receipts, tickets, OCR results, ticket PDFs/QRs)
-- stays in the Flutter app's local SQLite (Drift) store and is NEVER synced
-- here. That is a deliberate simplification, not a gap — see docs.
--
-- Server tables, in full: participants, profiles, contacts, lists,
-- list_members, expenses, expense_splits. That's it. Balances are a VIEW
-- over expense_splits, never a stored/duplicated total.

create extension if not exists "pgcrypto"; -- for gen_random_uuid()

-- ============================================================
-- Participants — the thing everything else references.
-- kind tells you which of profiles/contacts to join against.
-- ============================================================
create table public.participants (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('user', 'contact'))
);

-- ============================================================
-- Profiles (extends Supabase auth.users) — a real, logged-in participant.
-- ============================================================
create table public.profiles (
  participant_id uuid primary key references public.participants(id) on delete cascade,
  user_id uuid not null unique references auth.users(id) on delete cascade,
  display_name text not null,
  phone_number text unique, -- used to find contacts to claim at signup
  upi_id text,
  created_at timestamptz not null default now()
);

-- ============================================================
-- Contacts — a name+phone participant added on the fly by some payer.
-- No login. Multiple contact rows CAN share a phone_number (e.g. two
-- different payers each added "Rahul" independently before he signed up) —
-- deliberately not unique. Dedup happens at claim time, not creation time:
-- when a real profile signs up with a matching phone_number, every contact
-- row with that number gets claimed_by_participant_id set to the new
-- profile's participant_id. Old expense_splits keep referencing the
-- contact's participant_id unchanged, so no rows need rewriting — balance
-- queries follow claimed_by_participant_id to net everything onto the real
-- person (see pairwise_balances below).
-- ============================================================
create table public.contacts (
  participant_id uuid primary key references public.participants(id) on delete cascade,
  display_name text not null,
  phone_number text not null,
  created_by uuid not null references public.profiles(participant_id),
  claimed_by_participant_id uuid references public.participants(id),
  created_at timestamptz not null default now()
);

create index idx_contacts_phone_number on public.contacts(phone_number);

-- ============================================================
-- Lists — saved sets of participants for quick picking. Not a shared ledger.
-- ============================================================
create sequence public.list_account_seq start 1;

create table public.lists (
  id uuid primary key default gen_random_uuid(),
  account_number text not null unique, -- e.g. LST-0001
  name text not null, -- "Flatmates", "Goa Trip"
  created_by uuid not null references public.profiles(participant_id),
  created_at timestamptz not null default now()
);

create or replace function public.set_list_account_number()
returns trigger as $$
begin
  new.account_number := 'LST-' || lpad(nextval('public.list_account_seq')::text, 4, '0');
  return new;
end;
$$ language plpgsql;

create trigger trg_set_list_account_number
  before insert on public.lists
  for each row
  when (new.account_number is null)
  execute function public.set_list_account_number();

-- Who's in a list. Members can be users OR contacts (both are participants).
create table public.list_members (
  list_id uuid not null references public.lists(id) on delete cascade,
  participant_id uuid not null references public.participants(id) on delete cascade,
  added_at timestamptz not null default now(),
  primary key (list_id, participant_id)
);

-- ============================================================
-- Expenses
-- list_id is nullable + purely a tag: which saved list (if any) was used to
-- pick participants. It does NOT constrain who can be in expense_splits —
-- ad-hoc participants outside the list are always allowed.
-- No receipt_url / attachment column here on purpose — receipts are local-only.
-- ============================================================
create table public.expenses (
  id uuid primary key default gen_random_uuid(),
  list_id uuid references public.lists(id) on delete set null,
  payer_id uuid not null references public.participants(id),
  amount numeric(12,2) not null check (amount > 0),
  category text not null default 'Uncategorized',
  note text,
  split_type text not null default 'equal'
    check (split_type in ('equal', 'exact', 'percentage', 'shares')),
  created_at timestamptz not null default now()
);

create index idx_expenses_list_id on public.expenses(list_id);
create index idx_expenses_payer_id on public.expenses(payer_id);
create index idx_expenses_created_at on public.expenses(created_at);

-- ============================================================
-- Expense splits — one row per participant per expense.
-- share_amount is always the final resolved INR amount owed, regardless of
-- split_type — the Go backend resolves percentage/shares into concrete
-- amounts at write time.
-- ============================================================
create table public.expense_splits (
  id uuid primary key default gen_random_uuid(),
  expense_id uuid not null references public.expenses(id) on delete cascade,
  participant_id uuid not null references public.participants(id),
  share_amount numeric(12,2) not null check (share_amount >= 0),
  raw_input numeric(12,4), -- original percentage or share-count, for display/edit only
  unique (expense_id, participant_id)
);

create index idx_expense_splits_expense_id on public.expense_splits(expense_id);
create index idx_expense_splits_participant_id on public.expense_splits(participant_id);

-- ============================================================
-- Balances: computed on read via a view, not maintained.
--
-- Resolves claimed contacts to their real participant transparently: if a
-- split references a contact that's since been claimed, this view nets the
-- debt onto claimed_by_participant_id instead of the stale contact id, so a
-- person's full history (as contact + as real user) shows as one balance.
--
-- One row per (from_participant, to_participant) with a signed net amount:
-- positive means from_participant owes to_participant.
-- ============================================================
create view public.pairwise_balances as
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
group by
  coalesce(from_contact.claimed_by_participant_id, es.participant_id),
  coalesce(to_contact.claimed_by_participant_id, e.payer_id);

-- ============================================================
-- Row Level Security
-- ============================================================
alter table public.participants enable row level security;
alter table public.profiles enable row level security;
alter table public.contacts enable row level security;
alter table public.lists enable row level security;
alter table public.list_members enable row level security;
alter table public.expenses enable row level security;
alter table public.expense_splits enable row level security;

create policy "participants are viewable by everyone"
  on public.participants for select using (true);

create policy "profiles are viewable by everyone"
  on public.profiles for select using (true);

create policy "users can update own profile"
  on public.profiles for update using (auth.uid() = user_id);

create policy "contacts are viewable by everyone"
  on public.contacts for select using (true);

create policy "members can view their lists"
  on public.lists for select
  using (
    exists (
      select 1 from public.list_members lm
      join public.profiles p on p.participant_id = lm.participant_id
      where lm.list_id = lists.id and p.user_id = auth.uid()
    )
  );

create policy "authenticated users can create lists"
  on public.lists for insert
  with check (
    exists (
      select 1 from public.profiles p
      where p.participant_id = created_by and p.user_id = auth.uid()
    )
  );

create policy "members can view list membership"
  on public.list_members for select
  using (
    exists (
      select 1 from public.list_members lm2
      join public.profiles p on p.participant_id = lm2.participant_id
      where lm2.list_id = list_members.list_id and p.user_id = auth.uid()
    )
  );

create policy "participants can view expenses they're part of"
  on public.expenses for select
  using (
    exists (
      select 1 from public.profiles p
      where p.participant_id = expenses.payer_id and p.user_id = auth.uid()
    )
    or exists (
      select 1 from public.expense_splits es
      join public.profiles p on p.participant_id = es.participant_id
      where es.expense_id = expenses.id and p.user_id = auth.uid()
    )
  );

create policy "participants can view their splits"
  on public.expense_splits for select
  using (
    exists (
      select 1 from public.profiles p
      where p.participant_id = expense_splits.participant_id and p.user_id = auth.uid()
    )
    or exists (
      select 1 from public.expenses e
      join public.profiles p on p.participant_id = e.payer_id
      where e.id = expense_splits.expense_id and p.user_id = auth.uid()
    )
  );

-- Note: INSERT/UPDATE policies for expenses/splits/contacts are
-- intentionally omitted. Writes go through the Go backend using the
-- service role key (bypasses RLS), which enforces split-validation logic
-- (splits must sum to the expense total) and claim-time contact-merging
-- logic before committing.