import 'package:settl/database/daos/expenses_dao.dart';
import 'package:settl/models/expense.dart';
import 'package:settl/models/expense_split.dart';
import 'package:settl/repositories/interfaces/expense_repository.dart';

/// Drift-backed [ExpenseRepository].
///
/// Delegates all persistence to [ExpensesDao]; no HTTP or schema knowledge
/// leaks into the UI layer.
class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpensesDao _dao;

  ExpenseRepositoryImpl(this._dao);

  @override
  Future<Expense?> getExpenseById(String expenseId) =>
      _dao.getExpenseById(expenseId);

  @override
  Future<List<Expense>> getExpensesByUser(String userId) =>
      _dao.getExpensesByUser(userId);

  @override
  Future<List<Expense>> getExpensesByList(String listId) =>
      _dao.getExpensesByList(listId);

  @override
  Future<List<Expense>> getAllExpenses() => _dao.getAllExpenses();

  @override
  Future<void> createExpense(Expense expense) => _dao.createExpense(expense);

  @override
  Future<void> updateExpense(Expense expense) => _dao.updateExpense(expense);

  @override
  Future<void> deleteExpense(String expenseId) => _dao.deleteExpense(expenseId);

  @override
  Future<void> createExpenseSplit(ExpenseSplit split) =>
      _dao.createExpenseSplit(split);

  @override
  Future<List<ExpenseSplit>> getSplitsForExpense(String expenseId) =>
      _dao.getSplitsForExpense(expenseId);

  @override
  Future<void> deleteExpenseSplit(String splitId) =>
      _dao.deleteExpenseSplit(splitId);
}
