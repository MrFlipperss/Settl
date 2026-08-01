import 'package:settl/models/expense.dart';
import 'package:settl/models/expense_split.dart';

/// Contract for expense + split persistence.
///
/// Implementations back the UI with local storage (Drift DAOs) or, once the
/// sync layer lands, a remote API. The UI and services depend on this
/// interface only — never on HTTP or database details.
abstract class ExpenseRepository {
  Future<Expense?> getExpenseById(String expenseId);

  Future<List<Expense>> getExpensesByUser(String userId);

  /// All expenses recorded inside [listId].
  Future<List<Expense>> getExpensesByList(String listId);

  Future<List<Expense>> getAllExpenses();

  Future<void> createExpense(Expense expense);

  Future<void> updateExpense(Expense expense);

  /// Deletes the expense and all of its splits.
  Future<void> deleteExpense(String expenseId);

  Future<void> createExpenseSplit(ExpenseSplit split);

  Future<List<ExpenseSplit>> getSplitsForExpense(String expenseId);

  Future<void> deleteExpenseSplit(String splitId);
}
