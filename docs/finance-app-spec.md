# Rupee Ledger — Product Spec
*A personal + group financial tracker built around UPI, natural-language input, and lightweight AI*

---

## 0. Product thesis

Most expense trackers make you *fill out a form*. This app should feel like you're just **telling** it what happened — "₹100 dinner with Sarah" — and it does the categorizing, splitting, and filing. The AI is invisible plumbing, not a chatbot bolted on top.

Primary user: someone in India who pays via UPI, splits costs with roommates/friends/family, holds a few subscriptions, and travels enough to rack up train/flight/movie tickets.

---

## 1. Feature breakdown

### 1.1 Groups & numbered accounts
- Users create **Groups** (Flatmates, Goa Trip, Family) — each gets a sequential account number (e.g. `GRP-0042`) for easy reference/search, similar to how a bank passbook numbers accounts.
- Each group tracks: members, running balance per member, settled/unsettled status, currency.
- A person can belong to multiple groups; a "Balances" rollup shows net owed across all of them.

### 1.2 Expense logging with split
- Log an expense against a group or a 1:1 friend.
- Split modes: **Equal**, **Exact amounts**, **Percentage**, **Shares** (e.g. 2 shares vs 1).
- Optional line-itemization (split a restaurant bill by dish) — v2.
- Every expense stores: amount, payer, category, note, timestamp, attached receipt (optional).

### 1.3 Global consolidation
- One dashboard that nets out balances across all groups, friends, and currencies into a single "you're owed / you owe" number.
- Multi-currency support: store original currency + converted value at logged FX rate; don't silently reconvert historical entries.
- Filters: by person, by group, by time range.

### 1.4 UPI QR generation & sharing
- Generate a UPI deep-link (`upi://pay?pa=...&pn=...&am=...&tn=...`) as a scannable QR, pre-filled with amount + note (e.g. a settle-up amount).
- Share sheet: share the QR image or the raw UPI link (WhatsApp, copy link).
- Optional: save a personal "Request money" QR (static, no amount) for your profile.

### 1.5 Expense presets with AI/ML quick-add
- User-defined presets ("Chai ₹10", "Metro ₹30", "Sarah's rent split ₹6000") for one-tap logging.
- ML layer: after enough history, the app **suggests** presets based on time of day, location pattern, and frequency (e.g. it learns you buy coffee every weekday ~9am and surfaces that preset first).
- Auto-categorization: free-text notes get mapped to a category using a lightweight classifier (rules + embeddings), refined by user corrections.

### 1.6 AI budget tracker
- Per-category monthly budgets, auto-suggested from 3 months of history (rather than the user guessing cold).
- Pace tracking: "You're 60% through the month and 80% through your Food budget" style alerts.
- Anomaly flagging: unusual/duplicate charges surfaced for review, not auto-blocked.

### 1.7 Receipt photo capture
- Snap/upload a photo → OCR extracts merchant, date, total, (line items v2).
- Extracted fields are editable before saving — OCR is a first draft, not an autonomous write.
- Receipt image stored and linked to the expense for later reference/disputes.

### 1.8 Tip calculator
- Standard bill-splitting calculator: bill amount, tip %, number of people → per-person total.
- Can attach the result directly as a new expense (skips re-entering numbers).

### 1.9 Text-to-action ("Spotlight")
- A single global input, always one tap away, that parses free text into an action:
  - `₹100 dinner with sarah` → logs a split expense, 2-way, category Food
  - `set food budget 6000` → updates budget
  - `request 500 from rahul` → generates a UPI QR
  - `add netflix 499 monthly` → creates a subscription
- Shows a **preview chip** of what it understood before committing — always confirmable/editable, never silently executed.

### 1.10 Subscription tracking + trial alerts
- Track recurring subscriptions: amount, cycle (monthly/annual), renewal date, category.
- Free-trial alerts: if a card/UPI mandate was set up for a trial, remind the user 2–3 days before it converts to a paid charge.
- Monthly "subscription load" total shown alongside the budget view.

### 1.11 All-in-one ticket QR/wallet (train / flight / movie)
- Forward or upload a ticket (PDF/screenshot/QR) and the app extracts type, route/show, date-time, seat, PNR/booking ref.
- Stores all ticket QR codes in one wallet view, sorted by upcoming travel/shows, with a countdown.
- Optional: auto-logs the ticket price as an expense in the right category.

---

## 2. Cross-cutting notes

- **AI stays a co-pilot everywhere**: every "AI" action (categorize, budget suggestion, OCR read, ticket parse) surfaces as an editable suggestion, never a silent write. This matters most for money — trust is the product.
- **Offline-first logging**: expense entry and split math should work with no connection; sync (QR generation, OCR, ML suggestions) can be online-only.
- **Currency & locale**: default ₹/UPI-first, but the ledger model (groups, splits, budgets) is currency-agnostic for travel use.

## 3. Suggested phasing

| Phase | Includes |
|---|---|
| MVP | Groups, expense logging + split, global consolidation, tip calculator, manual presets |
| V2 | Spotlight text-to-action, UPI QR generation, AI budget tracker, receipt OCR |
| V3 | Subscription/trial alerts, ticket wallet + AI parsing, ML-personalized preset ranking |

---

## 4. What the prototype demonstrates

The accompanying interactive prototype mocks every feature above end-to-end in the UI (rule-based "AI" standing in for trained models, sample data standing in for OCR/bank feeds) so the flows, information architecture, and interaction model can be evaluated before any real ML/backend work begins.
