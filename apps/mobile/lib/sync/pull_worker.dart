import 'package:uuid/uuid.dart';

import '../api/collections_api.dart';
import '../api/expenses_api.dart';
import '../api/models/api_expense.dart';
import '../database/daos/expenses_dao.dart';
import '../database/daos/lists_dao.dart';
import '../models/collection.dart';
import '../models/expense.dart';
import '../models/expense_split.dart';

/// Pulls remote state into the local database (T8.3, pull half).
///
/// Downloads expenses (with splits) then collections, upserting rows into the
/// local Drift DAOs so the UI always reads from local storage. Contacts have
/// no list endpoint — they are reconciled via `claim` at bootstrap and search
/// (T10).
class PullWorker {
  PullWorker({
    required ExpensesApi expensesApi,
    required CollectionsApi collectionsApi,
    required ExpensesDao expensesLocal,
    required ListsDao listsLocal,
  })  : _expensesApi = expensesApi,
        _collectionsApi = collectionsApi,
        _expensesLocal = expensesLocal,
        _listsLocal = listsLocal;

  static const _uuid = Uuid();

  final ExpensesApi _expensesApi;
  final CollectionsApi _collectionsApi;
  final ExpensesDao _expensesLocal;
  final ListsDao _listsLocal;

  /// Pulls remote state into the local database: expenses (with splits) then
  /// collections.
  Future<void> refresh() async {
    await _refreshExpenses();
    await _refreshCollections();
  }

  Future<void> _refreshExpenses() async {
    final remote = await _expensesApi.listExpenses();
    for (final api in remote) {
      final local = _toLocalExpense(api);
      final existing = await _expensesLocal.getExpenseById(api.id);
      if (existing == null) {
        await _expensesLocal.createExpense(local);
      } else {
        await _expensesLocal.updateExpense(local);
      }
      await _replaceSplits(api);
    }
  }

  Future<void> _replaceSplits(ApiExpense api) async {
    final existing = await _expensesLocal.getSplitsForExpense(api.id);
    for (final split in existing) {
      await _expensesLocal.deleteExpenseSplit(split.id);
    }
    for (final apiSplit in api.splits) {
      await _expensesLocal.createExpenseSplit(ExpenseSplit(
        id: apiSplit.id ?? _uuid.v4(),
        expenseId: api.id,
        participantId: apiSplit.userId,
        shareAmount: apiSplit.shareAmountPaise / 100.0,
      ));
    }
  }

  Expense _toLocalExpense(ApiExpense api) => Expense(
        id: api.id,
        amount: api.amountPaise / 100.0,
        category: api.category,
        splitType: api.splitType,
        payerId: api.payerId,
        listId: api.groupId,
        note: api.note,
        version: api.version,
        createdAt: api.timestamp,
      );

  Future<void> _refreshCollections() async {
    final remote = await _collectionsApi.listCollections();
    for (final api in remote) {
      final local = Collection(
        id: api.id,
        name: api.name,
        accountNumber: api.accountNumber,
        createdBy: api.createdBy,
        createdAt: api.createdAt,
      );
      final existing = await _listsLocal.getCollectionById(api.id);
      if (existing == null) {
        await _listsLocal.createCollection(local);
      } else {
        await _listsLocal.updateCollection(local);
      }
    }
  }
}
