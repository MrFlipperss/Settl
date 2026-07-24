# Settl — Build Plan

Personal + group finance tracker. UPI-first, natural-language input, Flutter + Go + Supabase.
Full end-to-end prototype target, small team (2-4), monorepo.

Each phase below is written to be pasted standalone to an AI coding agent, with enough
context that the agent doesn't need the rest of this doc.

---

## Repo structure

\`\`\`
settl/
├── apps/
│   ├── mobile/          # Flutter app
│   └── backend/         # Go services
├── supabase/
│   ├── migrations/
│   └── functions/
├── docs/
│   └── finance-app-spec.md
└── README.md
\`\`\`

Stack: Flutter (mobile), Go (backend API), Supabase (Postgres + Auth + Storage + Realtime).

---

## Phase 0 — Foundations

**Goal:** repo scaffolding, tooling decisions, role split.

**Context for an agent:**
- Set up a monorepo with \`apps/mobile\` (Flutter) and \`apps/backend\` (Go), plus \`supabase/migrations\`.
- Flutter state management: choose Riverpod (preferred for testability with the offline-sync layer coming later).
- Go web framework: Chi or Fiber — lightweight, no heavy framework needed for this API surface.
- Define an OpenAPI spec early for the core endpoints (groups, expenses, splits, balances) so mobile and backend devs can build in parallel against a contract.

**Tasks:**
1. Scaffold Flutter project with Riverpod, basic navigation shell (bottom nav: Home, Groups, Spotlight, Budget, Profile).
2. Scaffold Go project with chosen router, health check endpoint, config loading (env vars for Supabase connection).
3. Init Supabase project, connect local CLI, set up migration folder structure.
4. Write \`openapi.yaml\` stub with paths for groups/expenses/balances (bodies can be empty initially).

**Team split (2-4 people):**
- Person A: Supabase schema + Go backend core
- Person B: Flutter shell + navigation + core logging UI
- Person C: Spotlight parser + rule-based categorization
- Person D (if 4th): UPI QR gen, receipt/ticket OCR stubs, polish

---

## Phase 1 — Data model & backend core

**Goal:** Postgres schema + Go endpoints for groups, expenses, splits, balances.

**Context for an agent:**
- This is the highest-risk part of the app — split math and balance netting handle real money math, so it needs unit tests before any UI touches it.
- Split modes to support: Equal, Exact amounts, Percentage, Shares (e.g. 2 shares vs 1 share).
- Groups get sequential human-readable account numbers (e.g. \`GRP-0042\`), similar to bank passbook numbering.

**Schema (build in this order):**
1. \`users\` — via Supabase Auth, no custom table needed beyond a profile extension.
2. \`groups\` (id, name, account_number via sequence/trigger, currency, created_at) + \`group_members\` (group_id, user_id, joined_at).
3. \`expenses\` (id, group_id nullable for 1:1, payer_id, amount, currency, fx_rate, category, note, timestamp, receipt_url nullable).
4. \`expense_splits\` (expense_id, user_id, split_type, share_amount or share_count).
5. Balances: compute on read initially (a SQL view or Go aggregation), not a maintained table — optimize to triggers/materialized views later if needed.

**Go endpoints:**
- \`POST /groups\`, \`POST /groups/:id/members\`
- \`POST /expenses\` — core logic: validate split adds up to 100%/total amount, write expense + splits atomically (use a DB transaction).
- \`GET /balances\` — netting logic across all groups/friends for one user, filterable by person/group/time range.

**Test requirement:** write the split-calculation and balance-netting logic as pure functions first, with unit tests covering all 4 split modes and edge cases (rounding remainders, uneven shares), before wiring to HTTP.

---

## Phase 2 — Flutter shell + MVP flows

**Goal:** working MVP UI — groups, expense logging, consolidation dashboard, tip calculator, presets.

**Context for an agent:**
- Offline-first is a hard requirement, not an enhancement — build local storage (Drift/SQLite) as the source of truth for logging from day one, with background sync to Supabase. Retrofitting this later is much harder than building it in.
- Build screens in this order: Groups list/create → Expense logging + split UI → Global consolidation dashboard → Tip calculator → Manual presets.
- The expense logging + split screen is the core UX of the app — prioritize getting the split-mode picker (equal/exact/percentage/shares) intuitive over any other screen.

**Tasks:**
1. Local schema (Drift) mirroring the Postgres schema for groups/expenses/splits.
2. Sync layer: queue local writes, push to Supabase/Go backend when online, handle conflict resolution (last-write-wins is fine for a prototype).
3. Groups list + create group flow, showing account number and member balances.
4. Expense logging screen with split-mode selector and per-person amount preview before saving.
5. Consolidation dashboard: single "you're owed / you owe" number, with filters by person/group/time range.
6. Tip calculator: bill amount, tip %, people count → per-person total, with a "log as expense" button.
7. Manual presets: user-defined one-tap buttons (e.g. "Chai ₹10"), stored locally, editable.

---

## Phase 3 — Spotlight & rule-based AI

**Goal:** the text-to-action input, plus auto-categorization.

**Context for an agent:**
- This is the product's differentiator, and per the product philosophy: "AI stays a co-pilot everywhere" — every parsed action must show an editable preview chip before committing, never a silent write.
- Prototype scope: rule-based parsing (regex/keyword extraction) stands in for a trained model. Don't build real ML here.

**Examples the parser must handle:**
- \`₹100 dinner with sarah\` → 2-way split expense, category Food
- \`set food budget 6000\` → budget update
- \`request 500 from rahul\` → generates UPI QR
- \`add netflix 499 monthly\` → creates subscription

**Tasks:**
1. Build a parser: extract amount (currency symbol/number), person name(s) (match against contacts/group members), category keyword (map keywords like "dinner", "movie", "uber" to categories), and action type (log expense / set budget / request money / add subscription).
2. Build the preview-chip UI component once — reuse it later for receipt OCR and ticket parsing confirmations, since all three share the same "AI drafts, human confirms" shape.
3. Auto-categorization: simple keyword-to-category dictionary first (e.g. "swiggy", "zomato" → Food); leave room to swap in embeddings-based classification later without changing the interface.

---

## Phase 4 — UPI QR + Budget view

**Goal:** UPI deep-link QR generation, sharing, and the AI-suggested budget tracker.

**Context for an agent:**
- UPI QR is low complexity: construct a \`upi://pay?pa=...&pn=...&am=...&tn=...\` deep link and render it as a QR code (Flutter: \`qr_flutter\` package). Add a share sheet (image or raw link) and an optional static "Request money" QR for the user's profile.
- Budget tracker for the prototype: use seeded sample data to demonstrate "3 months of history → suggested budget", rather than building real historical analysis — per the spec, sample data stands in for real ML/backend work at this stage.
- Pace tracking copy pattern: "You're 60% through the month and 80% through your Food budget."

**Tasks:**
1. UPI link builder + QR render + share sheet.
2. Static "Request money" profile QR (no amount).
3. Budget screen: per-category monthly budgets, suggested from sample historical data, editable by user.
4. Pace alerts: simple threshold-based banner when spend% exceeds time-elapsed% for a category.
5. Anomaly flagging: surface unusual/duplicate charges for review (not auto-blocked) — simple duplicate-detection heuristic (same amount + payee within a short window) is enough for the prototype.

---

## Phase 5 — Receipt OCR + Ticket wallet (mocked)

**Goal:** receipt capture and ticket wallet UI, with OCR/parsing mocked per prototype scope.

**Context for an agent:**
- Per the product spec, this phase mocks the hard ML/OCR parts with sample data — the goal is to prove the UI/UX, not build real OCR. Don't integrate a real OCR service yet.
- Extracted fields must always be editable before saving — OCR/parsing is a first draft, never an autonomous write.

**Tasks:**
1. Receipt capture: camera/upload flow → call a stubbed endpoint that returns a plausible fake extraction (merchant, date, total) after a short simulated delay → editable form → save, with image linked to the expense.
2. Ticket wallet: upload/forward a ticket (PDF/screenshot) → stubbed parser returns fake extracted fields (type, route/show, date-time, seat, PNR) → wallet view sorted by upcoming date with a countdown.
3. Optional: auto-log ticket price as an expense in the right category (reuse the preview-chip pattern from Phase 3).

---

## Phase 6 — Polish & demo prep

**Goal:** make the prototype demo-ready end-to-end.

**Tasks:**
1. Consistent empty/loading/error states across every screen built in Phases 2-5.
2. Seed realistic sample data: a few groups, several months of expense history, a couple of subscriptions, a ticket or two — enough that the demo doesn't look empty.
3. Full team walkthrough of the user journey end-to-end (create group → log expense → check balance → settle via QR → check budget → use Spotlight → check ticket wallet) to catch seams between phases.

---

## Sequencing principles (why this order)

- Backend split/balance logic is built and tested before any UI touches it — it's the part most likely to silently cost someone real money if wrong.
- Offline-first architecture is built into Phase 2 from the start, not retrofitted later.
- ML/OCR-heavy features (Phases 3, 5) are deliberately mocked/rule-based for the prototype, matching the product spec's explicit instruction that sample data and rule-based logic stand in for trained models at this stage.
