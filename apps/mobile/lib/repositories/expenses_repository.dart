import 'package:drift/drift.dart';
import 'package:settl/database/database.dart';
import 'package:settl/models/expense.dart';
import 'package:settl/models/expense_split.dart';

class ExpensesRepository {
  final Database _db;

  ExpensesRepository(this._db);

  // Helper to get the drift database instance
  dynamic get _driftDb {
    return (_db as dynamic).instance;
  }

  Future<Expense?> getExpenseById(String expenseId) async {
    final result = await (_driftDb.expenses)
        .where((tbl) => tbl.expenseId.equals(expenseId))
        .get()
        .first;

    return result.isNotEmpty ? Expense.fromJson(result.first.toJson()) : null;
  }

  Future<List<Expense>> getExpensesByUser(String userId) async {
    final result = await (_driftDb.expenses)
        .where((tbl) => tbl.payerId.equals(userId))
        .get();

    return result.map((row) => Expense.fromJson(row.toJson())).toList();
  }

  Future<List<Expense>> getAllExpenses() async {
    final result = await _driftDb.select(_driftDb.expenses).get();
    return result.map((row) => Expense.fromJson(row.toJson())).toList();
  }

  Future<void> createExpense(Expense expense) async {
    await _driftDb.into(_driftDb.expenses).insert(expense.toCompanion(true));
  }

  Future<void> updateExpense(Expense expense) async {
    await _driftDb.update(_driftDb.expenses).replace(expense.toCompanion(true));
  }

  Future<void> deleteExpense(String expenseId) async {
    await (_driftDb.expenses)
        .where((tbl) => tbl.expenseId.equals(expenseId))
        .delete();
  }

  // Expense Splits
  Future<void> createExpenseSplit(ExpenseSplit split) async {
    await _driftDb.into(_driftDb.expenseSplits).insert(split.toCompanion(true));
  }

  Future<List<ExpenseSplit>> getSplitsForExpense(String expenseId) async {
    final result = await (_driftDb.expenseSplits)
        .where((tbl) => tbl.expenseId.equals(expenseId))
        .get();

    return result.map((row) => ExpenseSplit.fromJson(row.toJson())).toList();
  }

  Future<void> updateExpenseSplit(ExpenseSplit split) async {
    await _driftDb.update(_driftDb.expenseSplits).replace(split.toCompanion(true));
  }

  Future<void> deleteExpenseSplit(String splitId) async {
    await (_driftDb.expenseSplits)
        .where((tbl) => tbl.id.equals(splitId))
        .delete();
  }
}