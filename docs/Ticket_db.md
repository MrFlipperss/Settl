## Phase 1 — Flutter Foundation

- [x] T1.1 (D) - Create Flutter project.

- [x] T1.2 (C) - Configure project architecture.

- [x] T1.3 (D) - Configure package dependencies.

- [x] T1.4 (C) - Create folder structure.

- [x] T1.5 (C) - Configure routing.

- [x] T1.6 (D) - Environment/config management.

- [x] T1.7 (D) - HTTP client.

- [x] T1.8 (D) - Secure token storage.

**Milestone:** Empty app with clean architecture.

---

## Phase 2 — Theme & Navigation

- [x] T2.1 (C) - Create Material 3 theme.

- [x] T2.2 (C) - Dark mode.

- [x] T2.3 (C) - Light mode.

- [x] T2.4 (C) - Theme switching.

- [x] T2.5 (C) - Navigation shell.

- [x] T2.6 (C) - Horizontal swipe navigation.

- [x] T2.7 (C) - Responsive layout.

**Milestone:** App skeleton.

---
## Phase 3 — Local Database

- [x] T3.1 (C) - Choose and configure Drift (or final DB).

- [x] T3.2 (D) - Database initialization.

- [x] T3.3 (D) - Expense table.
    
- [x] T3.4 (D) - Collection table.
    
- [x] T3.5 (D) - Contact table.
    
- [x] T3.6 (D) - Pending Sync table.
    
- [x] T3.7 (D) - DAO layer. Milestone: Fully functional local database.

---
## Phase 4 — Models

- [x] T4.1 (D) - Expense model.

- [x] T4.2 (D) - Contact model.

- [x] T4.3 (D) - Collection model.

- [x] T4.4 (D) - Balance model.

- [x] T4.5 (D) - Profile model.

- [x] T4.6 (D) - Serialization. Milestone: Shared domain models.


---
## Phase 5 — Repositories

- [x] T5.1 (C) - Repository interfaces.
    
- [x] T5.2 (D) - ExpenseRepository.
    
- [x] T5.3 (D) - ContactRepository.
    
- [x] T5.4 (D) - CollectionRepository.
    
- [x] T5.5 (D) - BalanceRepository.
    
- [x] T5.6 (D) - ProfileRepository. Milestone: UI never talks directly to HTTP.

---
## Phase 6 — Authentication

- [x] T6.1 (D) - Supabase login. Phone OTP via `AuthService.signInWithPhone` → `AuthRepository.sendOtp` (`signInWithOtp`, `OtpChannel.sms`). E.164 normalization via `phone_numbers_parser`.

- [x] T6.2 (D) - Signup. `AuthService.verifyOtp` → `AuthRepository.verifyOtp` (`verifyOTP`, `OtpType.sms`); login and signup are unified in the Supabase phone-OTP flow (`shouldCreateUser: true`).

- [x] T6.3 (D) - Session restore. `AuthRepository.restoreSession` reads `currentSession`; session persisted to secure storage via `SupabaseSecureStorage` (custom `LocalStorage` over `flutter_secure_storage`).

- [x] T6.4 (D) - Logout. `AuthService.signOut` → `AuthRepository.signOut` (`signOut`, local scope); clears the persisted session.

- [x] T6.5 (D) - Bootstrap profile. On first successful OTP verify, `AuthService` creates a local `Profile` row (generated participant UUID); backend reconciliation is handled by the sync layer (Phases 7–8).

- [x] T6.6 (D) - Token refresh. `AuthRepository.refreshSession` (`refreshSession`) + `autoRefreshToken: true` in `Supabase.initialize`. Milestone: Authentication complete.

---
## Phase 7 — API Layer

- [x] T7.1 (D) - Profile API. `ProfileApi.createProfile` (`POST /api/v1/profile`, idempotent 200/201 — not behind AuthMiddleware but requires a Bearer token) → wire DTO `ApiProfile` (snake_case, `participant_id`, nullable `upi_id`/`updated_at`/`deleted_at`).

- [x] T7.2 (D) - Contacts API. `ContactsApi.createContact` (`POST /v1/contacts`, 201), `searchContacts` (`GET /v1/contacts/search?q=`), `claimContacts` (`POST /v1/contacts/claim` → `{"claimed": int}`) → `ApiContact` / `ApiContactSearchResult`.

- [x] T7.3 (D) - Collections API. `CollectionsApi.createCollection` / `listCollections` (`POST|GET /v1/groups/`, trailing slash), `getCollection` (`GET /v1/groups/{id}`), `addMember` (`POST /v1/groups/{id}/members`, 201 empty body) → `ApiCollection` (`account_number`, `member_count`).

- [x] T7.4 (D) - Expenses API. `ExpensesApi.createExpense` / `listExpenses` / `getExpense` / `updateExpense` / `deleteExpense` (204) + `createReceipt` / `getReceipt` (`/v1/expenses/{id}/receipt`). Rupee doubles in → paise ints out (`amount_paise`); `groupID`/RFC3339 `from`/`to` filters; split types `equal`/`exact`/`percentage`/`shares`; `idempotency_key`; server-side `timestamp` key.

- [x] T7.5 (D) - Balances API. `BalancesApi.getBalances` (`GET /v1/balances`, optional `personID`) → `ApiBalancesResponse` (`total_owed_paise`, `total_owing_paise`, `net_paise`, `breakdown`).

- [x] T7.6 (D) - Health endpoint. `HealthApi.checkHealth` (`GET /health` at origin root — unauthenticated, backing client built from `apiRootUrlProvider` which strips the trailing `/api`). Milestone: Complete backend communication.

---
## Phase 8 — Synchronization

- [x] T8.1 (C) - Sync architecture. `SyncService` facade (`lib/sync/sync_service.dart`): `SyncStatus` idle/syncing/error, broadcast `statusStream`/`onlineStream`, `start`/`stop`/`requestSync`, single backoff retry timer; drains the queue then pulls remote state whenever the device comes online or `requestSync` is called.

- [x] T8.2 (D) - Pending operation queue. `SyncQueue` (`lib/sync/sync_queue.dart`) + `PendingSyncDao.getPendingRetryable(maxAttempts)`/`getFailed(maxAttempts)`. `enqueueExpense`/`enqueueContact`/`enqueueCollection`/`enqueueProfile` serialize the request DTO to a snake_case wire payload, baking a generated id into it so `entityId` and the replayed request id match (idempotent retries).

- [x] T8.3 (D) - Background sync worker. `SyncWorker` (`lib/sync/sync_worker.dart`): FIFO `drainQueue()` replays via the T7 API clients (`markSynced` on success); `refresh()` pulls expenses (with splits) and collections into the DAOs; unsupported ops (contact update/delete, profile delete, collection update/delete) fail permanently via `getFailed` instead of blocking the queue.

- [x] T8.4 (D) - Retry strategy. `RetryPolicy` (`lib/sync/retry_policy.dart`): maxAttempts=5, baseDelay=2s, maxDelay=2min, exponential backoff; transient = network errors + 408/429/5xx; permanent 4xx stops retrying and surfaces via `getFailed`.

- [x] T8.5 (D) - Startup sync. `SettlApp` → `ConsumerStatefulWidget`: post-frame `_startSync()` reconciles the remote profile (`POST /v1/profile`) + claims contacts matching the phone number, then starts the sync service; `ref.listenManual(authStateProvider, ...)` re-reconciles on session restore/sign-in. Bootstrap is best-effort — it no-ops (doesn't crash) where the auth stack is unavailable (widget tests).

- [x] T8.6 (D) - Connectivity listener. `ConnectivityGateway` + `ConnectivityGatewayImpl` (`lib/sync/connectivity_service.dart`) over `connectivity_plus` v7 list API (`any(r != none)`); `SyncService` subscribes on `start()` and drains whenever the device comes online.

- [x] T8.7 (D) - Conflict handling. `ConflictResolver` (`lib/sync/conflict_resolver.dart`): 409s emit a `ConflictResolutionEvent` and resolve server-wins (drop mutation, next refresh re-pulls) or keep-local (op moves to `getFailed` for manual review). Milestone: Offline-first working. Verified: 21 new sync tests + 4 widget tests (bootstrap degradation), 143 total passing; `dart analyze lib` clean for new code.
    
---
## Phase 9 — Home

- [ ] T9.1 (C) - Home page layout.
    
- [ ] T9.2 (C) - Search bar.
    
- [ ] T9.3 (D) - Recent expenses.
    
- [ ] T9.4 (D) - Quick actions.
    
- [ ] T9.5 (D) - Sync indicator. Milestone: Functional landing page.
    
---
## Phase 10 — Contacts

- [ ] T10.1 (C) - Contact search UI.
    
- [ ] T10.2 (D) - Backend integration.
    
- [ ] T10.3 (D) - Local search fallback.
    
- [ ] T10.4 (C) - Create new contact flow. Milestone: People-first workflow.
    
---
## Phase 11 — Add Expense

- [ ] T11.1 (C) - Expense screen.
    
- [ ] T11.2 (D) - Amount input.
    
- [ ] T11.3 (D) - Payer selection.
    
- [ ] T11.4 (D) - Participant selection.
    
- [ ] T11.5 (C) - Split editor.
    
- [ ] T11.6 (D) - Repository integration.
    
- [ ] T11.7 (D) - Offline save. Milestone: Core feature complete.
    
---
## Phase 12 — Collections

- [ ] T12.1 (C) - Collections list.
    
- [ ] T12.2 (C) - Create collection.
    
- [ ] T12.3 (D) - Edit collection.
    
- [ ] T12.4 (D) - Delete collection.
    
- [ ] T12.5 (D) - Use collection during expense creation. Milestone: Collections finished.
    
---
## Phase 13 — Balances

- [ ] T13.1 (C) - Balance screen.
    
- [ ] T13.2 (D) - Settlement UI.
    
- [ ] T13.3 (D) - Refresh integration. Milestone: Users can settle debts.
    
---
## Phase 14 — Polish

- [ ] T14.1 (C) - Animations.
    
- [ ] T14.2 (C) - Transitions.
    
- [ ] T14.3 (D) - Error handling.
    
- [ ] T14.4 (D) - Loading states.
    
- [ ] T14.5 (D) - Accessibility.
    
- [ ] T14.6 (D) - Performance optimization.
    
---
## Phase 15 — QA

- [ ] T15.1 (K) - Architecture review.
    
- [ ] T15.2 (K) - Dead code cleanup.
    
- [ ] T15.3 (K) - Consistency review.
    
- [ ] T15.4 (G) - Manual UX review.
    
- [ ] T15.5 (G) - Final roadmap review.
---