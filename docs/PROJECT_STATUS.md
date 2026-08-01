# Project Status

Last Updated: 2026-08-01

## Current Project Phase

**Current Phase:** Flutter Foundation

**Current Ticket:** T4.1 – Expense model (Phase 3 complete)

**Overall Progress:** ~65%

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
| T1.5 Routing | ✅ | Completed - GoRouter + StatefulShellRoute, verified with widget tests |
| T1.6 Environment config | ✅ | Completed - Environment management system implemented |
| T1.7 HTTP client | ✅ | Completed - HTTP client service with interceptors and logging |
| T1.8 Secure storage | ✅ | Completed - flutter_secure_storage service with Riverpod provider |

### Foundation Implemented

```
lib/
├── main.dart
├── app.dart
├── providers.dart
├── theme/
├── routing/
│   └── app_router.dart
├── features/
│   └── navigation/
│       └── shell.dart
├── models/
├── database/
│   ├── database.dart
│   ├── app_database.dart
│   ├── app_database.g.dart
│   └── daos/
│       ├── expenses_dao.dart
│       ├── contacts_dao.dart
│       ├── lists_dao.dart
│       ├── profiles_dao.dart
│       └── pending_sync_dao.dart
├── repositories/
├── services/
│   ├── http_client_service.dart
│   └── secure_storage_service.dart
└── sync/
```

~2065 lines of Dart in lib/.

---

## Phase 2 — Theme & Navigation

- Theme: ✅ Material 3 from brand seed
- Dark Mode: ✅
- Light Mode: ✅
- Theme Switching: ✅ System/Light/Dark selector on Profile tab
- Navigation Shell: ✅ Implemented with swipe support
- Swipe Navigation: ✅ Integrated with routing system
- Responsive Layout: ✅ NavigationRail ≥840dp, bottom bar below

---

## Phase 3 — Local Database

- Drift: ✅ Configured (drift ^2.28.2, drift_dev ^2.28.0, sqlite3, sqlite3_flutter_libs)
- Schema: ✅ 9 tables (Participants, Profiles, Contacts, Lists, ListMembers, Expenses, ExpenseSplits, ReceiptDetails, PendingSyncOperations)
- Database Initialization: ✅ AppDatabase with lazy open, migrations, foreign keys, Riverpod provider
- DateTime Storage: ✅ ISO-8601 text mode (UTC-safe roundtrips)
- DAO Layer: ✅ ExpensesDao, ContactsDao, ListsDao, ProfilesDao, PendingSyncDao
- Generated Code: ✅ app_database.g.dart + DAO mixins committed (build_runner)
- Tests: ✅ 19 DAO CRUD tests (NativeDatabase.memory), all passing
- Broken drift_database.dart: ✅ Removed (replaced by app_database.dart)

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
- [ ] T13.3 (D) - Refresh integration. Mile: Users can settle debts.

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
- Swipe navigation enabled
- Supabase Auth
- Render backend

---

## Known Issues

Phase 3 (Local Database) is complete: Drift schema (9 tables), DAO layer, providers, and 19 passing DAO tests.
Phase 2 (Theme & Navigation) is complete: Material 3 themes, system/light/dark switching, responsive shell.
Phase 1 is complete: routing (T1.5) verified with widget tests; secure token storage (T1.8) implemented with flutter_secure_storage.
Known pre-existing compile errors remain in lib/sync/sync_service.dart (imports supabase_flutter, not a dependency) and lib/repositories/auth_repository.dart (uses `_db.into` on abstract Database) - scheduled for Phases 7-8.
The old repositories (expenses/contacts/lists/profile/auth) still use the deprecated dynamic `_db` accessor and `toCompanion`/`toJson` patterns - will be rewritten on top of the DAO layer in Phase 5.

---

## AI Session Checklist

- [x] Read `flutter_app_context.md`
- [x] Read `PROJECT_STATUS.md`
- [x] Complete only one ticket
- [x] Avoid unrelated changes
- [x] Preserve architecture
- [x] Update this file when finished