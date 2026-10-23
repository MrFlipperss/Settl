import 'package:uuid/uuid.dart';

import 'package:settl/api/models/api_requests.dart';
import 'package:settl/database/daos/expenses_dao.dart';
import 'package:settl/models/expense.dart';
import 'package:settl/models/expense_split.dart';
import 'package:settl/repositories/interfaces/expense_repository.dart';
import 'package:settl/models/pending_sync_operation.dart';
import 'package:settl/sync/sync_queue.dart';

/// Drift-backed [ExpenseRepository].
///
/// Delegates all persistence to [ExpensesDao]; no HTTP or schema knowledge
/// leaks into the UI layer.
class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpensesDao _dao;
  final SyncQueue? _syncQueue;

  ExpenseRepositoryImpl(this._dao, [this._syncQueue]);

  static const _uuid = Uuid();

  @override
  Future<Expense?> getExpenseById(String expenseId) =>
      _dao.getExpenseById(expenseId);

  @override
  Future<List<Expense>> getExpensesByUser(String userId) =>
      _dao.getExpensesByUser(userId);

  @override
  Stream<List<Expense>> watchExpensesByUser(String userId) =>
      _dao.watchExpensesByUser(userId);

  @override
  Future<List<Expense>> getExpensesByList(String listId) =>
      _dao.getExpensesByList(listId);

  @override
  Future<List<Expense>> getAllExpenses() => _dao.getAllExpenses();

  @override
  Future<void> createExpense(Expense expense) => _dao.createExpense(expense);

  @override
  Future<Expense> createPeopleExpense({
    required String description,
    required int amountPaise,
    required String payerId,
    required List<String> participantIds,
  }) async {
    final name = description.trim();
    final ids = participantIds.map((id) => id.trim()).toList();
    final trimmedPayer = payerId.trim();
    if (name.isEmpty) throw ArgumentError('Description cannot be empty.');
    if (amountPaise <= 0) throw ArgumentError('Amount must be positive.');
    if (trimmedPayer.isEmpty || ids.isEmpty) {
      throw ArgumentError('Select at least one participant.');
    }
    if (ids.any((id) => id.isEmpty) || ids.toSet().length != ids.length) {
      throw ArgumentError('Participants must be valid and unique.');
    }
    if (!ids.contains(trimmedPayer)) {
      throw ArgumentError('The payer must be included in the split.');
    }
    final queue = _syncQueue;
    if (queue == null) throw StateError('Expense sync is not available.');

    final expenseId = _uuid.v4();
    final now = DateTime.now();
    final base = amountPaise ~/ ids.length;
    final remainder = amountPaise % ids.length;
    final expense = Expense(
      id: expenseId,
      amount: amountPaise / 100.0,
      category: 'Uncategorized',
      splitType: 'equal',
      payerId: trimmedPayer,
      note: name,
      idempotencyKey: expenseId,
      createdAt: now,
    );
    try {
      await _dao.createExpense(expense);
      for (var i = 0; i < ids.length; i++) {
        await _dao.createExpenseSplit(ExpenseSplit(
          id: _uuid.v4(),
          expenseId: expenseId,
          participantId: ids[i],
          shareAmount: (base + (i < remainder ? 1 : 0)) / 100.0,
        ));
      }
      await queue.enqueueExpense(
        operation: SyncOperation.insert,
        request: ApiCreateExpenseRequest(
          id: expenseId,
          payerId: trimmedPayer,
          amount: amountPaise / 100.0,
          splitType: 'equal',
          note: name,
          idempotencyKey: expenseId,
          splits: [
            for (final id in ids) ApiCreateSplitItem(userId: id),
          ],
        ),
      );
    } catch (_) {
      await _dao.deleteExpense(expenseId);
      rethrow;
    }
    return expense;
  }

  @override
  Future<void> updateExpense(Expense expense) => _dao.updateExpense(expense);

  @override
  Future<void> updatePeopleExpense({
    required String expenseId,
    required String description,
    required int amountPaise,
    required String payerId,
    required List<String> participantIds,
    required int expectedVersion,
  }) async {
    final name = description.trim();
    final ids = participantIds.map((id) => id.trim()).toList();
    final payer = payerId.trim();
    if (name.isEmpty) throw ArgumentError('Description cannot be empty.');
    if (amountPaise <= 0) throw ArgumentError('Amount must be positive.');
    if (payer.isEmpty || ids.isEmpty || !ids.contains(payer)) {
      throw ArgumentError('Select a valid payer and participants.');
    }
    if (ids.any((id) => id.isEmpty) || ids.toSet().length != ids.length) {
      throw ArgumentError('Participants must be valid and unique.');
    }
    final current = await _dao.getExpenseById(expenseId);
    if (current == null) throw StateError('Expense is no longer available.');
    final queue = _syncQueue;
    if (queue == null) throw StateError('Expense sync is not available.');
    final base = amountPaise ~/ ids.length;
    final remainder = amountPaise % ids.length;
    final updated = current.copyWith(
      amount: amountPaise / 100.0,
      payerId: payer,
      note: name,
      version: expectedVersion + 1,
    );
    final splits = [
      for (var i = 0; i < ids.length; i++)
        ExpenseSplit(
          id: _uuid.v4(),
          expenseId: expenseId,
          participantId: ids[i],
          shareAmount: (base + (i < remainder ? 1 : 0)) / 100.0,
        ),
    ];
    await _dao.replaceExpenseWithSplits(updated, splits);
    await queue.enqueueExpense(
      operation: SyncOperation.update,
      request: ApiCreateExpenseRequest(
        id: expenseId,
        payerId: payer,
        amount: amountPaise / 100.0,
        splitType: 'equal',
        note: name,
        idempotencyKey: current.idempotencyKey ?? expenseId,
        splits: [for (final id in ids) ApiCreateSplitItem(userId: id)],
      ),
    );
  }

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
