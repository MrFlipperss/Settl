import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'api/api_client.dart';
import 'api/balances_api.dart';
import 'api/collections_api.dart';
import 'api/contacts_api.dart';
import 'api/expenses_api.dart';
import 'api/health_api.dart';
import 'api/profile_api.dart';
import '../config/config_provider.dart';
import '../database/app_database.dart';
import '../database/daos/contacts_dao.dart';
import '../database/daos/expenses_dao.dart';
import '../database/daos/lists_dao.dart';
import '../database/daos/pending_sync_dao.dart';
import '../database/daos/profiles_dao.dart';
import '../models/auth_session.dart';
import '../repositories/auth_repository_impl.dart';
import '../repositories/balance_repository_impl.dart';
import '../repositories/collection_repository_impl.dart';
import '../repositories/contact_repository_impl.dart';
import '../repositories/expense_repository_impl.dart';
import '../repositories/interfaces/auth_repository.dart';
import '../repositories/interfaces/balance_repository.dart';
import '../repositories/interfaces/collection_repository.dart';
import '../repositories/interfaces/contact_repository.dart';
import '../repositories/interfaces/expense_repository.dart';
import '../repositories/interfaces/profile_repository.dart';
import '../repositories/profile_repository_impl.dart';
import '../services/auth_service.dart';
import '../services/http_client_service.dart';
import '../services/secure_storage_service.dart';
import '../sync/conflict_resolver.dart';
import '../sync/connectivity_service.dart';
import '../sync/pull_worker.dart';
import '../sync/push_worker.dart';
import '../sync/retry_policy.dart';
import '../sync/sync_queue.dart';
import '../sync/sync_service.dart';

/// Provider for the app's theme mode (light / dark / system).
/// Defaults to following the system setting; can be overridden from the
/// Profile settings screen.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// Provider for the selected accent preset index (see [accentPresets]).
/// Defaults to the first preset (Violet).
final accentIndexProvider = StateProvider<int>((ref) => 0);

/// Provider for tracking the current selected index in the bottom navigation bar.
/// This is now enhanced to work with our configuration system
final selectedIndexProvider = StateProvider<int>((ref) => 0);

/// Provider for the HTTP client service
final httpClientServiceProvider = Provider<HttpClientService>((ref) {
  return HttpClientService(ref);
});

/// Provider for the secure token storage service
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Provider for the local Drift database (opened lazily on first access).
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

/// Typed DAO providers backed by [appDatabaseProvider].
final expensesDaoProvider = Provider<ExpensesDao>((ref) {
  return ExpensesDao(ref.watch(appDatabaseProvider));
});

final contactsDaoProvider = Provider<ContactsDao>((ref) {
  return ContactsDao(ref.watch(appDatabaseProvider));
});

final listsDaoProvider = Provider<ListsDao>((ref) {
  return ListsDao(ref.watch(appDatabaseProvider));
});

final profilesDaoProvider = Provider<ProfilesDao>((ref) {
  return ProfilesDao(ref.watch(appDatabaseProvider));
});

final pendingSyncDaoProvider = Provider<PendingSyncDao>((ref) {
  return PendingSyncDao(ref.watch(appDatabaseProvider));
});

/// Repository providers — the UI-facing data layer. Each delegates to its
/// DAO provider; remote (HTTP) implementations will be swapped in later
/// phases behind the same interfaces.
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepositoryImpl(ref.watch(expensesDaoProvider));
});

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return ContactRepositoryImpl(
    ref.watch(contactsDaoProvider),
    ref.watch(contactsApiProvider),
  );
});

final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  return CollectionRepositoryImpl(ref.watch(listsDaoProvider));
});

final balanceRepositoryProvider = Provider<BalanceRepository>((ref) {
  return BalanceRepositoryImpl(ref.watch(expenseRepositoryProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    ref.watch(profilesDaoProvider),
    ref.watch(profileApiProvider),
  );
});

/// The initialized Supabase client. Requires `Supabase.initialize()` to have
/// completed in `main()` before any consumer reads this provider.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Auth repository backed by the Supabase client (phone OTP flow).
/// Listens to Supabase auth state changes and maps them to [AuthSession].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final repository = AuthRepositoryImpl(client.auth);
  ref.onDispose(repository.dispose);
  return repository;
});

/// Application-facing authentication facade.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    authRepository: ref.watch(authRepositoryProvider),
    profileRepository: ref.watch(profileRepositoryProvider),
  );
});

/// The current authentication session; null when signed out. Re-emits on
/// sign-in, sign-out and token refresh.
final authStateProvider = StreamProvider<AuthSession?>((ref) {
  return ref.watch(authRepositoryProvider).onAuthStateChanged;
});

/// Base [ApiClient] for authenticated `/api/v1` endpoints (T7). Injects the
/// current Supabase access token as the `Authorization: Bearer` header via
/// [authRepositoryProvider]; when no session exists requests go out without
/// it.
///
/// The token is read from [authRepositoryProvider] (not the higher-level
/// [authServiceProvider] facade) so the provider graph stays acyclic: the
/// facade depends on the profile repository, which now depends on the API
/// layer built on top of this client.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    client: ref.watch(httpClientProvider),
    baseUrl: ref.watch(apiBaseUrlProvider),
    tokenProvider: () =>
        ref.read(authRepositoryProvider).currentSession?.accessToken,
  );
});

/// Health check client (T7.6). `/health` lives at the origin root rather than
/// under `/api/v1`, so it uses [apiRootUrlProvider] and is unauthenticated.
final healthApiProvider = Provider<HealthApi>((ref) {
  return HealthApi(ApiClient(
    client: ref.watch(httpClientProvider),
    baseUrl: ref.watch(apiRootUrlProvider),
  ));
});

/// T7.1 — Profile API (create/idempotent-fetch of the backend profile).
final profileApiProvider = Provider<ProfileApi>((ref) {
  return ProfileApi(ref.watch(apiClientProvider));
});

/// T7.2 — Contacts API (create, search, claim).
final contactsApiProvider = Provider<ContactsApi>((ref) {
  return ContactsApi(ref.watch(apiClientProvider));
});

/// T7.3 — Collections (groups) API (create, list, get, add member).
final collectionsApiProvider = Provider<CollectionsApi>((ref) {
  return CollectionsApi(ref.watch(apiClientProvider));
});

/// T7.4 — Expenses API (CRUD + receipts).
final expensesApiProvider = Provider<ExpensesApi>((ref) {
  return ExpensesApi(ref.watch(apiClientProvider));
});

/// T7.5 — Balances API.
final balancesApiProvider = Provider<BalancesApi>((ref) {
  return BalancesApi(ref.watch(apiClientProvider));
});

// ---------------------------------------------------------------------------
// Sync layer (Phase 8)
// ---------------------------------------------------------------------------

/// Retry policy for the offline-first queue (T8.4).
final retryPolicyProvider = Provider<RetryPolicy>((ref) => const RetryPolicy());

/// Resolver for 409 version conflicts (T8.7). Server-wins by default.
final conflictResolverProvider = Provider<ConflictResolver>((ref) {
  final resolver = ConflictResolver();
  ref.onDispose(resolver.dispose);
  return resolver;
});

/// Device connectivity gateway (T8.6).
final connectivityGatewayProvider = Provider<ConnectivityGateway>((ref) {
  return ConnectivityGatewayImpl();
});

/// Mutation queue facade (T8.2) — offline-first writes go through this.
final syncQueueProvider = Provider<SyncQueue>((ref) {
  return SyncQueue(ref.watch(pendingSyncDaoProvider));
});

/// Replays queued local mutations against the backend (T8.3, push half).
final pushWorkerProvider = Provider<PushWorker>((ref) {
  return PushWorker(
    dao: ref.watch(pendingSyncDaoProvider),
    expensesApi: ref.watch(expensesApiProvider),
    contactsApi: ref.watch(contactsApiProvider),
    collectionsApi: ref.watch(collectionsApiProvider),
    profileApi: ref.watch(profileApiProvider),
    retryPolicy: ref.watch(retryPolicyProvider),
    conflictResolver: ref.watch(conflictResolverProvider),
  );
});

/// Pulls remote state into the local database (T8.3, pull half).
final pullWorkerProvider = Provider<PullWorker>((ref) {
  return PullWorker(
    expensesApi: ref.watch(expensesApiProvider),
    collectionsApi: ref.watch(collectionsApiProvider),
    expensesLocal: ref.watch(expensesDaoProvider),
    listsLocal: ref.watch(listsDaoProvider),
  );
});

/// App-facing sync facade (T8.1) — started at app launch (T8.5).
///
/// Plain (non-autoDispose) [Provider]: kept alive for the app's lifetime even
/// though the bootstrap only `ref.read`s it, so the sync loop survives past
/// the initial `start()` call. `onDispose` runs at container teardown.
final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(
    pushWorker: ref.watch(pushWorkerProvider),
    pullWorker: ref.watch(pullWorkerProvider),
    connectivity: ref.watch(connectivityGatewayProvider),
    retryPolicy: ref.watch(retryPolicyProvider),
  );
  ref.onDispose(() => service.stop());
  return service;
});
