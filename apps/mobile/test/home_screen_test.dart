// Widget tests for the T9 Home screen.
//
// Verifies the search bar affordance, quick-action row, recent-expenses list
// (rendered from a fake repository), the empty state, and that tapping the
// search bar navigates to the Spotlight tab.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:settl/app.dart';
import 'package:settl/config/app_environment.dart';
import 'package:settl/config/environment.dart';
import 'package:settl/features/spotlight/spotlight_screen.dart';
import 'package:settl/models/expense.dart';
import 'package:settl/models/expense_split.dart';
import 'package:settl/providers.dart';
import 'package:settl/repositories/interfaces/expense_repository.dart';

void main() {
  setUpAll(() async {
    // Mirrors main(): initializes AppConfig's late fields before the app boots.
    SharedPreferences.setMockInitialValues({});
    await Environment.init();
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
        payerId: 'u1',
        note: 'Lunch at cafe',
        createdAt: now,
      ),
      Expense(
        id: 'e2',
        amount: 45.50,
        category: 'Transport',
        splitType: 'equal',
        payerId: 'u2',
        note: 'Cab ride',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseRepositoryProvider
              .overrideWithValue(_FakeExpenseRepository(expenses: expenses)),
        ],
        child: const SettlApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lunch at cafe'), findsOneWidget);
    expect(find.text('Cab ride'), findsOneWidget);
    expect(find.text('\u20B9120.00'), findsOneWidget);
    expect(find.text('\u20B945.50'), findsOneWidget);
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

  testWidgets('Tapping the search bar navigates to the Spotlight screen',
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

    await tester.tap(find.text('Search people or add an expense'));
    await tester.pumpAndSettle();

    expect(find.byType(SpotlightScreen), findsOneWidget);
  });
}

/// Deterministic fake used to drive the recent-expenses section without the
/// Drift database (which throws [MissingPluginException] in widget tests).
class _FakeExpenseRepository implements ExpenseRepository {
  _FakeExpenseRepository({required this.expenses});

  final List<Expense> expenses;

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
    return expenses.where((e) => e.payerId == userId).toList();
  }

  @override
  Future<List<Expense>> getExpensesByList(String listId) async {
    return expenses.where((e) => e.listId == listId).toList();
  }

  @override
  Future<void> createExpense(Expense expense) async {}

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
