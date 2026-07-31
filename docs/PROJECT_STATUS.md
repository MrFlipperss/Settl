# Project Status

Last Updated: 2026-07-30

## Current Project Phase

**Current Phase:** Flutter Foundation

**Current Ticket:** T1.5 – Routing

**Overall Progress:** ~20%

---

## Current Priorities

1. Review generated Flutter foundation against `flutter_app_context.md`.
2. Replace direct Supabase repositories with offline-first repositories.
3. Introduce a local database (Drift recommended).
4. Implement the synchronization layer.
5. Begin the core expense workflow.

---

## Phase 0 — Backend Finalization

| Ticket | Status | Notes |
|--------|--------|-------|
| T0.1 Review backend architecture | ✅ | Completed |
| T0.2 Optional group_id | ✅ | Completed |
| T0.3 Contact search endpoint | ✅ | Completed |
| T0.4 Sync metadata | ✅ | Completed |
| T0.5 API verification | ✅ | Completed |

---

## Phase 1 — Flutter Foundation

| Ticket | Status | Notes |
|--------|--------|-------|
| T1.1 Create Flutter project | ✅ | Completed |
| T1.2 Architecture | ✅ | Architecture defined |
| T1.3 Dependencies | ✅ | Supabase, Riverpod, UUID |
| T1.4 Folder structure | ✅ | Complete |
| T1.4a Architecture Alignment | ✅ | Completed - Offline-first with Drift |
| T1.5 Routing | 🟡 | Bottom-nav exists, migrate to swipe navigation later |
| T1.6 Environment config | ⬜ | |
| T1.7 HTTP client | 🟡 | Via Supabase client |
| T1.8 Secure storage | ⬜ | |

### Foundation Implemented

```
lib/
├── main.dart
├── app.dart
├── providers.dart
├── theme/
├── routing/
├── models/
├── database/
│   ├── database.dart
│   ├── drift_database.dart
│   ├── drift_database.g.dart
│   └── supabase_database.dart
├── repositories/
├── services/
└── sync/
```

~650 lines of new Dart.

---

## Phase 2 — Theme & Navigation

- Theme: 🟡
- Dark Mode: 🟡
- Light Mode: 🟡
- Theme Switching: ⬜
- Navigation Shell: 🟡
- Swipe Navigation: ⬜

---

## Phase 3 — Local Database

Not started.

---

## Phase 4 — Models

Status: 🟡 Partial

---

## Phase 5 — Repositories

Status: 🟡 Partial

### Target architecture:

UI → Repository → Local DB → Sync Layer → Backend

---

## Phase 6 — Authentication

- Login: 🟡
- Signup: 🟡
- Session Restore: ⬜
- Logout: ⬜
- Bootstrap Profile: ⬜
- Token Refresh: ⬜

---

## Phase 7 — API Layer

Status: 🟡 Partial

---

## Phase 8 — Synchronization

- Sync Architecture: 🟡
- Pending Queue: ⬜
- Sync Worker: ⬜
- Retry Strategy: ⬜
- Startup Sync: ⬜
- Connectivity Listener: ⬜
- Conflict Handling: ⬜

---

## Phase 9 — Home

- [ ] T9.1 (C) - Home page layout
- [ ] T9.2 (C) - Search bar
- [ ] T9.3 (D) - Recent expenses
- [ ] T9.4 (D) - Quick actions
- [ ] T9.5 (D) - Sync indicator. Milestone: Functional landing page.

---

## Phase 10 — Contacts

- [ ] T10.1 (C) - Contact search UI
- [ ] T10.2 (D) - Backend integration
- [ ] T10.3 (D) - Local search fallback
- [ ] T10.4 (C) - Create new contact flow. Milestone: People-first workflow.

---

## Phase 11 — Add Expense

- [ ] T11.1 (C) - Expense screen
- [ ] T11.2 (D) - Amount input
- [ ] T11.3 (D) - Payer selection
- [ ] T11.4 (D) - Participant selection
- [ ] T11.5 (C) - Split editor
- [ ] T11.6 (D) - Repository integration
- [ ] T11.7 (D) - Offline save. Milestone: Core feature complete.

---

## Phase 12 — Collections

- [ ] T12.1 (C) - Collections list
- [ ] T12.2 (C) - Create collection
- [ ] T12.3 (D) - Edit collection
- [ ] T12.4 (D) - Delete collection
- [ ] T12.5 (D) - Use collection during expense creation. Milestone: Collections finished.

---

## Phase 13 — Balances

- [ ] T13.1 (C) - Balance screen
- [ ] T13.2 (D) - Settlement UI
- [ ] T13.3 (D) - Refresh integration. Milestone: Users can settle debts.

---

## Phase 14 — Polish

- [ ] T14.1 (C) - Animations
- [ ] T14.2 (C) - Transitions
- [ ] T14.3 (D) - Error handling
- [ ] T14.4 (D) - Loading states
- [ ] T14.5 (D) - Accessibility
- [ ] T14.6 (D) - Performance optimization

---

## Phase 15 — QA

- [ ] T15.1 (K) - Architecture review
- [ ] T15.2 (K) - Dead code cleanup
- [ ] T15.3 (K) - Consistency review
- [ ] T15.4 (G) - Manual UX review
- [ ] T15.5 (G) - Final roadmap review.

---

## Active Decisions

- Offline-first
- People-first UX
- Collections optional
- Local DB is source of truth
- Backend owns business logic
- Material 3
- Minimal UI
- Search-first workflow
- Planned swipe navigation
- Supabase Auth
- Render backend

---

## Known Issues

Repositories have been successfully migrated to use the local Drift database with synchronization layer ready for implementation.

---

## AI Session Checklist

- [x] Read `flutter_app_context.md`
- [x] Read `PROJECT_STATUS.md`
- [x] Complete only one ticket
- [ ] Avoid unrelated changes
- [ ] Preserve architecture
- [x] Update this file when finished