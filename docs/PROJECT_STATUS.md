# Project Status

Last Updated: 2026-08-02

## Current Project Phase

**Current Phase:** Synchronization

**Current Ticket:** Phase 8 complete — T9.1 Home page layout (next)

**Overall Progress:** ~86%

---

## Current Priorities

1. **Phase 9 — Home (in progress):** T9.1–T9.5 search-first landing page — prominent search/spotlight input (primary action), compact recent expenses, quick actions, subtle sync indicator; explicitly NOT a dashboard. Milestone: functional landing page.
2. **Phase 10 — Contacts:** T10.1–T10.4 — contact search UI, backend integration, local search fallback, create-contact flow (`PhoneUtils.normalizePhone` E.164 mandate). Milestone: people-first workflow.
3. **Phase 11 — Add Expense:** T11.1–T11.7 — expense screen, amount/payer/participant selection, split editor, repository integration, offline save. Milestone: core feature complete.
4. **Phase 12 — Collections:** T12.1–T12.5 — collections list, create/edit/delete, use during expense creation.
5. **Phase 13 — Balances:** T13.1–T13.3 — balance screen, settlement UI, refresh integration. Users can settle debts.

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

Status: ✅ Complete — all seven tickets (T8.1–T8.7) shipped with 21 passing sync tests + 4 widget tests. Offline-first is now working end to end: mutations are queued locally (`PendingSyncOperations`), replayed FIFO by the worker against the T7 API clients with exponential backoff, conflicts resolved server-wins by default, and remote state pulled into the local DAOs on startup / reconnect. `SettlApp` bootstraps the sync layer post-first-frame (reconcile profile + claim contacts, then start the service); bootstrap degrades to a no-op where the auth stack is unavailable (widget tests).

```
lib/sync/
├── sync_service.dart        # facade: status/online streams, start/stop/requestSync, retry timer
├── sync_queue.dart          # enqueue mutations (id baked into payload for idempotent replay)
├── push_worker.dart         # FIFO drain + replay of queued mutations (T8.3, push half)
├── pull_worker.dart         # remote refresh → local DAOs (expenses w/ splits, collections; T8.3, pull half)
├── retry_policy.dart        # maxAttempts 5, baseDelay 2s, maxDelay 2min, transient 408/429/5xx
├── connectivity_service.dart# ConnectivityGateway over connectivity_plus v7
└── conflict_resolver.dart   # 409 → server-wins (drop) or keep-local (getFailed)
```

- Sync Architecture (T8.1): ✅ `SyncService` facade
- Pending Queue (T8.2): ✅ `SyncQueue` + `getPendingRetryable`/`getFailed`
- Sync Worker (T8.3): ✅ FIFO drain + pull refresh
- Retry Strategy (T8.4): ✅ `RetryPolicy` exponential backoff
- Startup Sync (T8.5): ✅ post-frame bootstrap in `app.dart` (best-effort)
- Connectivity Listener (T8.6): ✅ `ConnectivityGatewayImpl` (connectivity_plus v7 list API)
- Conflict Handling (T8.7): ✅ `ConflictResolver` server-wins default. Milestone: Offline-first working.
- Tests: ✅ 21 sync tests (`test/sync_test.dart`, MockClient + FakeConnectivityGateway) + 4 widget tests; full suite 143 passing; `dart analyze lib` clean for new code (13 pre-existing warnings remain in `config/environment.dart` + `services/http_client_service.dart`)

---

## Post-Phase-8 Architecture Audit

Status: ✅ Complete — full read-through of `apps/mobile` (Flutter) and `apps/backend` (Go) with fixes F1–F7. `dart analyze lib` = 13 warnings (all pre-existing in `config/environment.dart` + `services/http_client_service.dart`); `flutter test` = 147/147 passing.

### Assessment: 8.5/10

The offline-first layering (UI → Repository → Local DB → Sync → Backend) holds and repositories are the only data seam. Deductions: legacy `ListModel` naming persisted into the domain layer, dead scaffolding from earlier phases, one layering violation that bypassed repositories at bootstrap, and an oversized single sync worker.

### Files changed (F1–F7)

| Fix | What |
|-----|------|
| F1 | `app.dart` bootstrap now calls `ProfileRepository.ensureRemoteProfile` + `ContactRepository.claimContacts` instead of API clients directly; both repository impls take API clients; `apiClientProvider` token sourced from `authRepositoryProvider` (broke a provider cycle the repo→API wiring introduced) |
| F2 | `BalanceRepositoryImpl` depends on `ExpenseRepository` (not `ExpensesDao`) — repositories no longer import other aggregates' DAOs |
| F3 | Domain naming: `ListModel`→`Collection`, `ListMember`→`CollectionMember` (files → `collection.dart`/`collection_member.dart`); DAO/repo/sync methods collection-flavored; `CollectionMember.listId`→`collectionId`; wire keys + tables unchanged |
| F4 | Deleted dead `lib/database/database.dart`; dropped `implements Database` + its members (`instance`/`initialize()`) from `AppDatabase` |
| F5 | Deleted dead `exampleConfigProvider` from `providers.dart` |
| F6 | Deleted dead `lib/services/expense_service.dart` |
| F7 | Split `SyncWorker` → `PushWorker` (drain/replay/conflict) + `PullWorker` (remote refresh); `SyncService`, providers, and tests updated |

### Fixed vs intentional

**Fixed (audit):** repo-bypass in app bootstrap; `BalanceRepositoryImpl`→DAO dependency; stale "List*" naming; dead `Database` interface / `expense_service` / `exampleConfigProvider`; monolithic worker.
**Intentional (left as-is):** generated drift `.g.dart` files (build_runner output, regenerated — never hand-edited); `Lists`/`ListMembers` table names + `Expense.listId` + `list_id` wire keys (schema/backend compat); backend 409 `expectedVersion: 0` quirk (defensive `ConflictResolver`); 13 pre-existing analyzer warnings; `HealthApi`/`BalancesApi` scaffolding (tested T7 artifacts).

### Remaining recommendations

- Rename drift tables `Lists`/`ListMembers` → `Collections`/`CollectionMembers` and `Expense.listId`→`collectionId` in a schema migration (v3) so domain naming is complete end-to-end.
- Clear the 13 analyzer warnings (unused `prefs` in `config/environment.dart`; unnecessary `!` + unused `dart:io` import in `services/http_client_service.dart`).
- T9.1 home-screen work (`lib/features/home/home_screen.dart` + test) is uncommitted in-tree — commit before building further phases.

---

## UI Design Principles (product direction — apply to all future UI work)

Established during the T9 home-screen polish. Treat as guardrails, not suggestions.

1. **Minimal over maximal.** Keep the home screen as minimal as possible. Continuously ask whether another element can be *removed* rather than added. Every new element is a cost, not a win.
2. **Sync stays an implementation detail.** Do NOT enable the sync indicator unless it is completely invisible when idle and only appears while syncing, offline, or on error. Synchronization should never surface as a first-class UI element. (The existing `_SyncIndicator` already satisfies the visibility contract; it remains gated off pending a deliberate decision.)
3. **Search bar is the primary interaction point.** Quick actions must not compete with it — keep them quiet, and reduce or remove them if they ever become redundant.
4. **People-first, not list-first.** Collections are optional shortcuts, never the primary organizational unit. The UI should always feel people-first.
5. **Conversational language.** Prefer conversational phrasing (e.g. "You paid ₹500") over raw data presentation (e.g. "Amount: ₹500") in future screens.
6. **Time-grouped recents (future).** Eventually group recent expenses by "Today", "Yesterday", etc. instead of a single flat "Recent" list. `_formatDate` in `home_screen.dart` already computes the Today/Yesterday distinction.
7. **Effortless recording is the differentiator.** Avoid adding features or visual clutter. The app's biggest differentiator is how effortless it feels to record an expense — not how much information it displays.

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
Phase 7 (API Layer) is complete: `ApiClient` + 6 domain API clients with 34 passing MockClient tests; the sync layer (Phase 8) now consumes them.
Phase 8 (Synchronization) is complete: the pre-existing compile error in `lib/sync/sync_service.dart` (uses `client` getter on abstract Database) is fixed — the file was rewritten as the `SyncService` facade; 21 new sync tests + 4 widget tests, 143 total passing.
Post-Phase-8 audit (F1–F7) is complete: repo-bypass in bootstrap fixed, BalanceRepository decoupled from ExpensesDao, List*/ListMember renamed to Collection/CollectionMember, dead `database.dart`/`expense_service.dart`/`exampleConfigProvider` removed, `SyncWorker` split into `PushWorker`+`PullWorker`; 147/147 tests passing, analyzer at the 13-warning baseline.
The old orphaned auth/API scaffolding (auth_service, api_service, auth_repository, profile_api_repository) was removed in Phase 5 - authentication was rebuilt in Phase 6 with Supabase; the API layer follows in Phase 7.

---

## AI Session Checklist

- [x] Read `flutter_app_context.md`
- [x] Read `PROJECT_STATUS.md`
- [x] Complete only one ticket
- [x] Avoid unrelated changes
- [x] Preserve architecture
- [x] Update this file when finished