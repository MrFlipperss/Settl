import 'package:drift/drift.dart';

import '../app_database.dart';
import '../../models/expense.dart';
import '../../models/expense_split.dart';

part 'expenses_dao.g.dart';

/// CRUD access to [Expenses] and [ExpenseSplits], mapped to domain models.
@DriftAccessor(tables: [Expenses, ExpenseSplits])
class ExpensesDao extends DatabaseAccessor<AppDatabase>
    with _$ExpensesDaoMixin {
  ExpensesDao(super.db);

  Future<Expense?> getExpenseById(String expenseId) async {
    final row = await (select(expenses)
          ..where((tbl) => tbl.expenseId.equals(expenseId)))
        .getSingleOrNull();
    return row == null ? null : _expenseFromRow(row);
  }

  Future<List<Expense>> getExpensesByUser(String userId) async {
    final rows = await (select(expenses)
          ..where((tbl) => tbl.payerId.equals(userId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .get();
    return rows.map(_expenseFromRow).toList();
  }

  Future<List<Expense>> getAllExpenses() async {
    final rows = await (select(expenses)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .get();
    return rows.map(_expenseFromRow).toList();
  }

  Future<void> createExpense(Expense expense) async {
    await into(expenses).insert(ExpensesCompanion.insert(
      expenseId: expense.id,
      amount: expense.amount,
      category: expense.category,
      splitType: expense.splitType,
      payerId: expense.payerId,
      listId: Value(expense.listId),
      note: Value(expense.note),
      idempotencyKey: Value(expense.idempotencyKey),
      version: Value(expense.version),
      createdAt: expense.createdAt,
    ));
  }

  Future<void> updateExpense(Expense expense) async {
    await (update(expenses)..where((tbl) => tbl.expenseId.equals(expense.id)))
        .write(ExpensesCompanion(
      amount: Value(expense.amount),
      category: Value(expense.category),
      splitType: Value(expense.splitType),
      payerId: Value(expense.payerId),
      listId: Value(expense.listId),
      note: Value(expense.note),
      version: Value(expense.version),
    ));
  }

  Future<void> deleteExpense(String expenseId) async {
    await (delete(expenses)..where((tbl) => tbl.expenseId.equals(expenseId)))
        .go();
    await (delete(expenseSplits)
          ..where((tbl) => tbl.expenseId.equals(expenseId)))
        .go();
  }

  // -- Expense splits -------------------------------------------------------

  Future<void> createExpenseSplit(ExpenseSplit split) async {
    await into(expenseSplits).insert(ExpenseSplitsCompanion.insert(
      id: split.id,
      expenseId: split.expenseId,
      participantId: split.participantId,
      shareAmount: split.shareAmount,
      rawInput: Value(split.rawInput),
    ));
  }

  Future<List<ExpenseSplit>> getSplitsForExpense(String expenseId) async {
    final rows = await (select(expenseSplits)
          ..where((tbl) => tbl.expenseId.equals(expenseId)))
        .get();
    return rows.map(_splitFromRow).toList();
  }

  Future<void> deleteExpenseSplit(String splitId) async {
    await (delete(expenseSplits)..where((tbl) => tbl.id.equals(splitId))).go();
  }

  // -- Mappers --------------------------------------------------------------

  Expense _expenseFromRow(ExpenseRow row) => Expense(
        id: row.expenseId,
        amount: row.amount,
        category: row.category,
        splitType: row.splitType,
        payerId: row.payerId,
        listId: row.listId,
        note: row.note,
        idempotencyKey: row.idempotencyKey,
        version: row.version,
        createdAt: row.createdAt,
      );

  ExpenseSplit _splitFromRow(ExpenseSplitRow row) => ExpenseSplit(
        id: row.id,
        expenseId: row.expenseId,
        participantId: row.participantId,
        shareAmount: row.shareAmount,
        rawInput: row.rawInput,
      );
}
