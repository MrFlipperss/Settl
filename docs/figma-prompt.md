# Settl — Mobile App UI Design Prompt (for Figma)

## 1. Product Overview
Design the mobile UI for **Settl**, an expense-splitting and UPI-settlement app for Indian users. Core value: users log expenses (even by typing them in natural language like "dinner 500 sarah"), track who owes whom, and settle instantly via UPI. The app is offline-first with local storage and syncs to a backend.

**Target audience:** young Indian professionals splitting rent, trips, meals, subscriptions with friends and flatmates.

**Design language:** modern, premium, dark-first. Think Apple Liquid Glass meets Notion. Smooth, minimal, confident. All amounts in INR (₹).

**Platform:** iOS first (iPhone), responsive to Android.

---

## 2. Design System

### Colors
- **Background:** deep navy-black `#0A0E17` (base), elevated surfaces `#101624` / `#151C2E`
- **Borders:** subtle `#232E45`
- **Primary accent:** electric indigo/blue `#6C8CFF`, secondary `#A78BFA` (purple)
- **Text:** near-white `#E8EDF7` primary, muted `#9AA7C0` secondary
- **Semantic:** green `#34D399` (owed to me / positive), red `#F87171` (I owe / negative), amber `#FBBF24` (Food/categories)
- **Light mode:** optional — include a light variant if time permits (clean white `#F7F8FB`, same accents)

### Typography
- System font stack (SF Pro on iOS, Roboto on Android)
- Numeric emphasis: tabular figures for all money
- Hierarchy: 34px bold for hero amounts, 15-17px for titles, 13-14px for body, 11-12px for captions/labels

### Components
- Cards: 14-18px corner radius, 1px border, subtle inner glow
- Category icon tiles: rounded 12px with tinted background per category (Food 🍕, Rent 🏠, Transport 🚇, Entertainment 🎬, Shopping 🛍, Utilities 💡)
- Avatars: circular, friend photos
- Badges: small rounded pills for categories
- Pill filters: horizontal scrollable chips
- Bottom tab bar: blurred (frosted glass), 5 tabs max
- Expense/balance amounts: colored (green = incoming, red = outgoing)

---

## 3. Screens (design at 390×844, iPhone 14/15 frame)

### S1 — Onboarding / Login
- 3 quick screens: value prop ("Split anything", "Track who owes whom", "Settle via UPI instantly") with illustrations
- Login: phone number + OTP entry, "Continue with Google/Apple" options
- Keep minimal — auth is secondary for this app; skip heavy marketing

### S2 — Home (Dashboard) — MOST IMPORTANT SCREEN
Layout, top to bottom:
1. **Header:** Settl logo mark (rounded square badge with "S", indigo→purple gradient) + user avatar top-right
2. **Net balance hero card:** gradient card showing "Net Balance" label, large amount (e.g. +₹1,700), status line ("You are owed on net"), two side stats: "Owed to me" (green) and "I owe" (red)
3. **Spotlight bar:** prominent pill-shaped command bar — "Ask Settl… log a new expense" (this is the natural-language entry; show a suggestion chip like "dinner 500 sarah")
4. **Follow-ups section:** list of friends with balances — left accent strip (green = owes you, red = you owe), avatar, name, amount; each row tappable → settlement flow
5. **Recent expenses:** latest 4-5 expense cards (category icon tile, note, "paid by X · date · N splits", badge, amount)
6. **Quick actions** (optional row): Log Expense, Split, Scan Receipt, Tip Calculator — icon buttons

### S3 — Expense Modal / Log Expense (bottom sheet)
- Opened from Spotlight bar or quick action
- Fields: Amount (big numeric, INR), Note/Description, Category picker (icon grid), Payer (defaults to you), Split type segmented control: Equal / Exact / Percentage / Shares
- Split participant selection: avatars + names, tap to toggle, each shows computed share live
- Bottom: total check ("Splits sum to ₹500 ✓") + "Add Expense" CTA
- Validation state: error if splits don't sum to total

### S4 — Expenses List
- Header: "Expenses"
- Filter pills: All / Food / Rent / Entertainment / Transport…
- Grouped by date (Today, Yesterday, Jul 18…) or flat list of expense cards (same card as S2.5)
- Pull-to-refresh; empty state: "No expenses yet" with illustration + CTA

### S5 — Expense Detail
- Tappable from list: full amount hero, category badge, note, paid-by row, date
- Split breakdown: each participant row (avatar, name, share amount, "You paid ₹250" for payer)
- Actions: Edit, Delete (only payer), Share receipt (if any)

### S6 — Groups
- Header: "Groups"
- Group cards: cover image (32px thumbnail), name, member count, avatars row (stacked), total spend; tap → group detail
- "New Group" floating action button / header plus
- Group detail: members, expenses within group, per-member owed columns (simplified: settle up per member)

### S7 — Balances
- Full-screen breakdown: section "Who owes you" (green rows), "Who you owe" (red rows)
- Each row: avatar, name, amount, chevron
- Tap row → settle flow: amount, payer/recipient, "Generate UPI QR" (show a QR code card with amount + VPA), copy-UPI-button, payment status tracking

### S8 — Profile / Settings
- User info: avatar, name, phone, UPI VPA (editable)
- Sections list: Budgets (category targets + progress bars), Subscriptions (Netflix, Spotify… with renewal dates), Tickets (train/movie/flight with QR), Backup & Sync, Theme toggle (dark/light), Log out

### S9 — Receipt Scan (OCR) [secondary]
- Camera frame UI, upload photo, confidence states, parsed line items → auto-fill expense

### S10 — Tip Calculator [secondary]
- Bill amount, tip %, split count → per-person share; button "Add as expense"

---

## 4. Interaction Notes (annotate in Figma prototypes)
- Bottom tab bar: Home / Expenses / Groups / Balances (+ Profile if 5 tabs)
- All money updates animate (count-up) when balances change
- Row taps have subtle press state (scale 0.98 / dim)
- Bottom sheets slide up with rounded 24px top corners, grab handle
- Empty states everywhere: friendly illustration + one-line copy + CTA

## 5. Deliverables
- One Figma file, organized in pages: Design System, Screens, Prototype
- Interactive prototype: Home → Expense log → list → detail → settle (QR)
- Export the following as SVG/PNG: logo badge, empty-state illustrations, category icons
- Component library: cards, buttons, chips, tab bar, input fields, list rows, avatars

## 6. Constraints
- Mobile-first, portrait orientation
- Keep every screen to max ~2 levels deep (sheets/modals instead of new pages where possible)
- Consistency over novelty — reuse components everywhere
- All sample data in mockups in Indian context (₹, names like Sarah/Rahul/Ananya, Goa trip, UPI IDs like sarah@upi)
