import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settl/database/database.dart';
import 'package:settl/database/drift_database.dart';
import 'repositories/auth_repository.dart';
import 'repositories/contacts_repository.dart';
import 'repositories/expenses_repository.dart';
import 'repositories/lists_repository.dart';
import 'repositories/profile_repository.dart';
import 'services/auth_service.dart';
import 'services/expense_service.dart';
import 'sync/sync_service.dart';

final databaseProvider = Provider<Database>((ref) {
  throw UnimplementedError('Must override databaseProvider in main');
});

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(databaseProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(databaseProvider)),
);

final contactsRepositoryProvider = Provider<ContactsRepository>(
  (ref) => ContactsRepository(ref.watch(databaseProvider)),
);

final listsRepositoryProvider = Provider<ListsRepository>(
  (ref) => ListsRepository(ref.watch(databaseProvider)),
);

final expensesRepositoryProvider = Provider<ExpensesRepository>(
  (ref) => ExpensesRepository(ref.watch(databaseProvider)),
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(
    ref.watch(authRepositoryProvider),
    ref.watch(profileRepositoryProvider),
  ),
);

final expenseServiceProvider = Provider<ExpenseService>(
  (ref) => ExpenseService(ref.watch(expensesRepositoryProvider)),
);

final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(ref.watch(databaseProvider)),
);