# Project Status

Last Updated: 2026-08-01

## Current Project Phase

**Current Phase:** API Layer

**Current Ticket:** T7.1 – Profile API (Phase 6 complete)

**Overall Progress:** ~82%

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

- Expense Model: ✅ Present with copyWith/equality + snake_case JSON
- Contact Model: ✅ Present with copyWith/equality + snake_case JSON
- Collection Model: ✅ ListModel + ListMember with copyWith/equality
- Balance Model: ✅ New - mirrors pairwise_balances view (from_participant, to_participant, amount_owed)
- Profile Model: ✅ Profile + Participant with copyWith/equality
- Serialization: ✅ All 10 models round-trip via fromJson/toJson, tested
- copyWith: ✅ Sentinel-based null-clearing on all nullable fields
- Tests: ✅ 28 model serialization/equality tests, all passing

---

## Phase 5 — Repositories

Status: ✅ Complete

- Repository Interfaces: ✅ ExpenseRepository, ContactRepository, CollectionRepository, BalanceRepository, ProfileRepository in `lib/repositories/interfaces/`
- ExpenseRepository: ✅ `ExpenseRepositoryImpl` (DAO-backed, incl. splits + list-scoped reads)
- ContactRepository: ✅ `ContactRepositoryImpl` (DAO-backed)
- CollectionRepository: ✅ `CollectionRepositoryImpl` (DAO-backed, incl. membership)
- BalanceRepository: ✅ `BalanceRepositoryImpl` — computes pairwise net balances from local expense splits, mirroring the backend `pairwise_balances` view
- ProfileRepository: ✅ `ProfileRepositoryImpl` (DAO-backed)
- Providers: ✅ 5 repository providers wired to DAO providers in `providers.dart`
- Milestone: ✅ UI never talks directly to HTTP (repositories are the only data seam)
- Tests: ✅ 18 repository tests (CRUD + balance computation), all passing
- Cleanup: ✅ Removed deprecated dynamic-`_db` repositories + broken orphaned auth/API scaffolding (auth_repository, profile_api_repository, auth_service, api_service) — auth/API rebuilt properly in Phases 6–7

### Target architecture:

UI → Repository → Local DB → Sync Layer → Backend

---

## Phase 6 — Authentication

Status: ✅ Complete

- Dependencies: ✅ `supabase_flutter ^2.16.0` (gotrue 2.26.0, supabase 2.14.0) + `phone_numbers_parser ^9.0.25` (maintained fork of discontinued `phone_number`)
- Phone OTP: ✅ `AuthService.signInWithPhone` sends SMS OTP (`signInWithOtp`, `OtpChannel.sms`); login and signup unified in the Supabase phone-OTP flow (`shouldCreateUser: true`)
- OTP Verify: ✅ `AuthService.verifyOtp` → `verifyOTP` with `OtpType.sms`; returns domain `AuthSession`
- E.164 Normalization: ✅ `PhoneUtils.normalizePhone` via `phone_numbers_parser` (sync API — adapted from the async `phone_number` example in `flutter_app_context.md`)
- Session Restore: ✅ `AuthRepository.restoreSession` reads `currentSession`
- Logout: ✅ `AuthService.signOut` (local scope)
- Bootstrap Profile: ✅ `AuthService` creates a local `Profile` row on first sign-in (generated participant UUID; backend reconciliation deferred to sync layer)
- Token Refresh: ✅ `AuthRepository.refreshSession` + `autoRefreshToken: true`
- Secure Session Persistence: ✅ `SupabaseSecureStorage` — custom `LocalStorage` over `flutter_secure_storage` (Android Keystore / iOS Keychain), honoring T1.8 (credentials only in secure storage, never SharedPreferences)
- Providers: ✅ `supabaseClientProvider`, `authRepositoryProvider`, `authServiceProvider`, `authStateProvider` (StreamProvider) in `providers.dart`
- App Init: ✅ `Supabase.initialize` in `main()` with secure localStorage
- Tests: ✅ 18 auth tests (normalizePhone, AuthSession model, AuthService with fake repositories), all passing

### Phase 6 file map

```
lib/
├── utils/
│   └── phone_utils.dart
├── models/
│   └── auth_session.dart
├── repositories/
│   ├── interfaces/
│   │   └── auth_repository.dart
│   └── auth_repository_impl.dart
└── services/
    ├── auth_service.dart
    └── supabase_secure_storage.dart
```

---

## Phase 7 — API Layer

Status: ✅ Complete — all six tickets (T7.1–T7.6) shipped with 34 passing `MockClient` tests. Wire DTOs (`lib/api/models/`) mirror the Go backend JSON exactly (snake_case, paise ints in responses, rupee doubles in requests); the pure-Dart `ApiClient` injects the Supabase access token via `tokenProvider`; domain clients are Riverpod-wired (`apiClientProvider` + per-resource providers) for the Phase 8 sync layer.

```
lib/api/
├── api_client.dart          # get/post/put/delete, Bearer token, {"error"} → ApiException
├── api_exception.dart
├── health_api.dart          # GET /health (root URL, unauthenticated)
├── profile_api.dart         # POST v1/profile (idempotent 200/201)
├── contacts_api.dart        # create / search?q= / claim
├── collections_api.dart     # groups CRUD + addMember
├── expenses_api.dart        # expenses CRUD + receipt upsert/fetch
├── balances_api.dart        # GET v1/balances (personID)
└── models/                  # 9 wire DTO files (api_health, api_profile, api_contact,
                             # api_contact_search_result, api_collection, api_expense,
                             # api_balance, api_receipt, api_requests)
```

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

Phase 6 (Authentication) is complete: phone OTP login/signup, session restore, logout, local profile bootstrap, token refresh; 18 passing auth tests; session persisted via SupabaseSecureStorage over flutter_secure_storage.
Phase 5 (Repositories) is complete: 5 repository interfaces + DAO-backed implementations, 18 passing repository tests, deprecated dynamic-`_db` repos removed.
Phase 4 (Models) is complete: Balance model added, all 10 domain models have copyWith (sentinel-based null clearing), value equality, and snake_case JSON round-trip serialization, verified by 28 model tests.
Phase 3 (Local Database) is complete: Drift schema (9 tables), DAO layer, providers, and 19 passing DAO tests.
Phase 2 (Theme & Navigation) is complete: Material 3 themes, system/light/dark switching, responsive shell.
Phase 1 is complete: routing (T1.5) verified with widget tests; secure token storage (T1.8) implemented with flutter_secure_storage.
Known pre-existing compile error remains only in lib/sync/sync_service.dart (uses `client` getter on abstract Database) - scheduled for Phase 8 (Synchronization). The prior `uri_does_not_exist` on its supabase_flutter import cleared once supabase_flutter became a dependency in Phase 6.
The old orphaned auth/API scaffolding (auth_service, api_service, auth_repository, profile_api_repository) was removed in Phase 5 - authentication was rebuilt in Phase 6 with Supabase; the API layer follows in Phase 7.

---

## AI Session Checklist

- [x] Read `flutter_app_context.md`
- [x] Read `PROJECT_STATUS.md`
- [x] Complete only one ticket
- [x] Avoid unrelated changes
- [x] Preserve architecture
- [x] Update this file when finished