// Widget tests for the T9 Home screen.
//
// Verifies the search bar affordance, quick-action row, recent-expenses list
// (rendered from a fake repository), the empty state, and that tapping the
// search bar navigates to the Spotlight tab.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:settl/app.dart';
import 'package:settl/config/app_environment.dart';
import 'package:settl/models/auth_session.dart';
import 'package:settl/models/expense.dart';
import 'package:settl/models/expense_split.dart';
import 'package:settl/models/profile.dart';
import 'package:settl/providers.dart';
import 'package:settl/repositories/interfaces/expense_repository.dart';
import 'package:settl/repositories/interfaces/profile_repository.dart';
import 'package:settl/services/auth_service.dart';

import 'helpers/fake_auth_repository.dart';

void main() {
  setUpAll(() async {
    // Mirrors main(): initializes AppConfig's late fields before the app boots.
    SharedPreferences.setMockInitialValues({});
    await AppConfig().initialize(environment: AppEnvironment.development);
  });

  testWidgets(
      'Home renders the AppBar title, search bar hint, and quick-action labels',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseRepositoryProvider
              .overrideWithValue(_FakeExpenseRepository(expenses: const [])),
        ],
        child: const SettlApp(),
      ),
    );
    await tester.pumpAndSettle();

    // AppBar title is 'Settl'; the nav bar label 'Home' also renders.
    expect(find.text('Settl'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(
      find.text('Search people or add an expense'),
      findsOneWidget,
    );
    expect(find.text('Add expense'), findsOneWidget);
    expect(find.text('Add person'), findsOneWidget);
    expect(find.text('View groups'), findsOneWidget);
  });

  testWidgets('Recent expenses render with note text and rupee amounts',
      (tester) async {
    final now = DateTime.now();
    final expenses = [
      Expense(
        id: 'e1',
        amount: 120.0,
        category: 'Food',
        splitType: 'equal',
        payerId: 'p1',
        note: 'Lunch at cafe',
        createdAt: now,
      ),
      Expense(
        id: 'e2',
        amount: 45.50,
        category: 'Transport',
        splitType: 'equal',
        payerId: 'p2',
        note: 'Cab ride',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Expense(
        id: 'e3',
        amount: 900,
        category: 'Shopping',
        splitType: 'equal',
        payerId: 'p2',
        note: 'Other account purchase',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ];
    const session = AuthSession(userId: 'auth-1', accessToken: 'test-token');
    final profile = Profile(
      userId: 'auth-1',
      participantId: 'p1',
      displayName: 'Test User',
      phoneNumber: '+911234567890',
      createdAt: now,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(session)),
          profileRepositoryProvider.overrideWithValue(
            _FakeProfileRepository(profile),
          ),
          authServiceProvider.overrideWithValue(AuthService(
            authRepository: FakeAuthRepository(),
            profileRepository: _FakeProfileRepository(profile),
          )),
          expenseRepositoryProvider.overrideWithValue(_FakeExpenseRepository(
            expenses: expenses,
            splitParticipants: const {
              'e2': {'p1'}
            },
          )),
        ],
        child: const SettlApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lunch at cafe'), findsOneWidget);
    expect(find.text('Cab ride'), findsOneWidget);
    expect(find.text('\u20B9120.00'), findsOneWidget);
    expect(find.text('\u20B945.50'), findsOneWidget);
    expect(find.text('Other account purchase'), findsNothing);
  });

  testWidgets('Signed-out users do not see account-specific expenses',
      (tester) async {
    final expense = Expense(
      id: 'private',
      amount: 120,
      category: 'Food',
      splitType: 'equal',
      payerId: 'p1',
      note: 'Private account expense',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          expenseRepositoryProvider.overrideWithValue(
            _FakeExpenseRepository(expenses: [expense]),
          ),
        ],
        child: const SettlApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Private account expense'), findsNothing);
    expect(find.text('No expenses yet'), findsOneWidget);
  });

  testWidgets('Empty repository shows the "No expenses yet" empty state',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseRepositoryProvider
              .overrideWithValue(_FakeExpenseRepository(expenses: const [])),
        ],
        child: const SettlApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No expenses yet'), findsOneWidget);
  });

  testWidgets('Entering text in the search bar updates the inline search input',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseRepositoryProvider
              .overrideWithValue(_FakeExpenseRepository(expenses: const [])),
        ],
        child: const SettlApp(),
      ),
    );
    await tester.pumpAndSettle();

    final searchFinder = find.byType(TextField);
    await tester.enterText(searchFinder, 'Coffee');
    await tester.pumpAndSettle();

    expect(find.text('Coffee'), findsOneWidget);
  });
}

/// Deterministic fake used to drive the recent-expenses section without the
/// Drift database (which throws [MissingPluginException] in widget tests).
class _FakeExpenseRepository implements ExpenseRepository {
  _FakeExpenseRepository({
    required this.expenses,
    this.splitParticipants = const {},
  });

  final List<Expense> expenses;
  final Map<String, Set<String>> splitParticipants;

  @override
  Future<List<Expense>> getAllExpenses() async => expenses;

  @override
  Future<Expense?> getExpenseById(String expenseId) async {
    for (final e in expenses) {
      if (e.id == expenseId) return e;
    }
    return null;
  }

  @override
  Future<List<Expense>> getExpensesByUser(String userId) async {
    return expenses
        .where((expense) =>
            expense.payerId == userId ||
            splitParticipants[expense.id]?.contains(userId) == true)
        .toList();
  }

  @override
  Stream<List<Expense>> watchExpensesByUser(String userId) => Stream.value(
        expenses
            .where((expense) =>
                expense.payerId == userId ||
                splitParticipants[expense.id]?.contains(userId) == true)
            .toList(),
      );
  @override
  Future<void> updatePeopleExpense(
      {required String expenseId,
      required String description,
      required int amountPaise,
      required String payerId,
      required List<String> participantIds,
      required int expectedVersion}) async {}

  @override
  Future<List<Expense>> getExpensesByList(String listId) async {
    return expenses.where((e) => e.listId == listId).toList();
  }

  @override
  Future<void> createExpense(Expense expense) async {}

  @override
  Future<Expense> createPeopleExpense({
    required String description,
    required int amountPaise,
    required String payerId,
    required List<String> participantIds,
    String category = 'Uncategorized',
    String? groupId,
    String splitType = 'equal',
    Map<String, num> splitValues = const {},
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> updateExpense(Expense expense) async {}

  @override
  Future<void> deleteExpense(String expenseId) async {}

  @override
  Future<void> createExpenseSplit(ExpenseSplit split) async {}

  @override
  Future<List<ExpenseSplit>> getSplitsForExpense(String expenseId) async {
    return const [];
  }

  @override
  Future<void> deleteExpenseSplit(String splitId) async {}
}

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository(this.profile);

  final Profile profile;

  @override
  Future<Profile?> getProfileByUserId(String userId) async =>
      userId == profile.userId ? profile : null;

  @override
  Future<Profile?> getProfileByParticipantId(String participantId) async =>
      participantId == profile.participantId ? profile : null;

  @override
  Future<List<Profile>> getAllProfiles() async => [profile];

  @override
  Future<void> createProfile(Profile profile) async {}

  @override
  Future<void> updateProfile(Profile profile) async {}

  @override
  Future<void> deleteProfileByUserId(String userId) async {}

  @override
  Future<Profile> ensureRemoteProfile(Profile profile) async => profile;
}
