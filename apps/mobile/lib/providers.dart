import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

/// Provider for the app's theme mode (light / dark / system).
/// Defaults to following the system setting; can be overridden from the
/// Profile settings screen.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// Provider for tracking the current selected index in the bottom navigation bar.
/// This is now enhanced to work with our configuration system
final selectedIndexProvider = StateProvider<int>((ref) => 0);

/// Example of how to use configuration values in providers
final exampleConfigProvider = Provider<String>((ref) {
  final config = ref.watch(appConfigProvider);
  return 'Running ${config.appName} v${config.appVersion} in ${config.environment} mode';
});

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
  return ContactRepositoryImpl(ref.watch(contactsDaoProvider));
});

final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  return CollectionRepositoryImpl(ref.watch(listsDaoProvider));
});

final balanceRepositoryProvider = Provider<BalanceRepository>((ref) {
  return BalanceRepositoryImpl(ref.watch(expensesDaoProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.watch(profilesDaoProvider));
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