import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../api/api_exception.dart';
import '../api/collections_api.dart';
import '../api/contacts_api.dart';
import '../api/expenses_api.dart';
import '../api/models/api_expense.dart';
import '../api/models/api_requests.dart';
import '../api/profile_api.dart';
import '../database/daos/expenses_dao.dart';
import '../database/daos/lists_dao.dart';
import '../database/daos/pending_sync_dao.dart';
import '../models/expense.dart';
import '../models/expense_split.dart';
import '../models/list_model.dart';
import '../models/pending_sync_operation.dart';
import 'conflict_resolver.dart';
import 'retry_policy.dart';
import 'sync_queue.dart';

/// Replays queued mutations against the backend and pulls remote state into
/// the local database (T8.3).
///
/// Drain is FIFO (oldest first) and skips operations that have exhausted their
/// retry budget, so a permanently failed operation cannot block the queue.
/// A successful replay confirms the operation ([PendingSyncDao.markSynced]);
/// transient failures bump the attempt count and are retried on the next drain;
/// permanent failures surface via [PendingSyncDao.getFailed]; 409 conflicts are
/// handed to the [ConflictResolver].
class SyncWorker {
  SyncWorker({
    required PendingSyncDao dao,
    required ExpensesApi expensesApi,
    required ContactsApi contactsApi,
    required CollectionsApi collectionsApi,
    required ProfileApi profileApi,
    required ExpensesDao expensesLocal,
    required ListsDao listsLocal,
    required RetryPolicy retryPolicy,
    required ConflictResolver conflictResolver,
  })  : _dao = dao,
        _expensesApi = expensesApi,
        _contactsApi = contactsApi,
        _collectionsApi = collectionsApi,
        _profileApi = profileApi,
        _expensesLocal = expensesLocal,
        _listsLocal = listsLocal,
        _retryPolicy = retryPolicy,
        _conflictResolver = conflictResolver;

  static const _uuid = Uuid();

  final PendingSyncDao _dao;
  final ExpensesApi _expensesApi;
  final ContactsApi _contactsApi;
  final CollectionsApi _collectionsApi;
  final ProfileApi _profileApi;
  final ExpensesDao _expensesLocal;
  final ListsDao _listsLocal;
  final RetryPolicy _retryPolicy;
  final ConflictResolver _conflictResolver;

  /// Drains the retryable queue FIFO. Returns the number of operations
  /// confirmed synced.
  Future<int> drainQueue() async {
    final pending = await _dao.getPendingRetryable(_retryPolicy.maxAttempts);
    var synced = 0;
    for (final op in pending) {
      if (await _replay(op)) synced++;
    }
    return synced;
  }

  /// Pulls remote state into the local database: expenses (with splits) then
  /// collections. Contacts have no list endpoint — they are reconciled via
  /// `claim` at bootstrap and search (T10).
  Future<void> refresh() async {
    await _refreshExpenses();
    await _refreshCollections();
  }

  Future<bool> _replay(PendingSyncOperation op) async {
    try {
      await _dispatch(op);
      await _dao.markSynced(op.operationId, DateTime.now());
      return true;
    } on ApiException catch (error) {
      if (error.statusCode == 409) {
        await _resolveConflict(op, error);
      } else {
        await _recordFailure(op, error);
      }
      return false;
    } catch (error) {
      await _recordFailure(op, error);
      return false;
    }
  }

  Future<void> _resolveConflict(
    PendingSyncOperation op,
    ApiException error,
  ) async {
    final resolution = _conflictResolver.resolve(
      entityType: op.entityType,
      entityId: op.entityId,
      message: error.message,
    );
    switch (resolution) {
      case ConflictResolution.keepServer:
        // Server wins: drop the local mutation; the next refresh overwrites
        // the local row with the server version.
        await _dao.deleteOperation(op.operationId);
      case ConflictResolution.keepLocal:
        // Preserve the mutation for manual review: it moves out of the
        // retryable pool and surfaces via getFailed().
        await _dao.markFailed(
          op.operationId,
          attemptCount: _retryPolicy.maxAttempts,
          error: 'conflict: ${error.message}',
        );
    }
  }

  Future<void> _recordFailure(PendingSyncOperation op, Object error) async {
    final attempts = op.attemptCount + 1;
    if (_retryPolicy.isTransient(error)) {
      // Retryable: bump the attempt count; the operation stays in the
      // retryable pool until maxAttempts is reached.
      await _dao.markFailed(
        op.operationId,
        attemptCount: attempts,
        error: error.toString(),
      );
    } else {
      // Permanent (validation/authz 4xx, unsupported operation): stop retrying
      // so the FIFO queue is never blocked; surface via getFailed().
      await _dao.markFailed(
        op.operationId,
        attemptCount: _retryPolicy.maxAttempts,
        error: error.toString(),
      );
    }
  }

  Future<void> _dispatch(PendingSyncOperation op) async {
    final payload = jsonDecode(op.payload) as Map<String, dynamic>;
    switch (op.entityType) {
      case SyncQueue.entityExpense:
        await _dispatchExpense(op, payload);
      case SyncQueue.entityContact:
        await _dispatchContact(op, payload);
      case SyncQueue.entityCollection:
        await _dispatchCollection(op, payload);
      case SyncQueue.entityProfile:
        await _dispatchProfile(op, payload);
      default:
        throw StateError('Unknown sync entity type: ${op.entityType}');
    }
  }

  Future<void> _dispatchExpense(
    PendingSyncOperation op,
    Map<String, dynamic> payload,
  ) async {
    final request = ApiCreateExpenseRequest.fromJson(payload);
    switch (op.operation) {
      case SyncOperation.insert:
        await _expensesApi.createExpense(request);
      case SyncOperation.update:
        await _expensesApi.updateExpense(op.entityId, request);
      case SyncOperation.delete:
        await _expensesApi.deleteExpense(op.entityId);
    }
  }

  Future<void> _dispatchContact(
    PendingSyncOperation op,
    Map<String, dynamic> payload,
  ) async {
    switch (op.operation) {
      case SyncOperation.insert:
        await _contactsApi
            .createContact(ApiCreateContactRequest.fromJson(payload));
      case SyncOperation.update:
      case SyncOperation.delete:
        // The backend exposes no contact update/delete endpoints; these fail
        // permanently and surface via getFailed().
        throw UnsupportedError(
            'No backend endpoint for contact ${op.operation.name}');
    }
  }

  Future<void> _dispatchCollection(
    PendingSyncOperation op,
    Map<String, dynamic> payload,
  ) async {
    switch (op.operation) {
      case SyncOperation.insert:
        await _collectionsApi
            .createCollection(ApiCreateCollectionRequest.fromJson(payload));
      case SyncOperation.update:
      case SyncOperation.delete:
        throw UnsupportedError(
            'No backend endpoint for collection ${op.operation.name}');
    }
  }

  Future<void> _dispatchProfile(
    PendingSyncOperation op,
    Map<String, dynamic> payload,
  ) async {
    switch (op.operation) {
      case SyncOperation.insert:
      case SyncOperation.update:
        // POST /v1/profile is an idempotent upsert keyed by the caller.
        await _profileApi.createProfile(ApiCreateProfileRequest.fromJson(payload));
      case SyncOperation.delete:
        throw UnsupportedError('No backend endpoint for profile delete');
    }
  }

  // -- Pull (refresh) --------------------------------------------------------

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
      final local = ListModel(
        id: api.id,
        name: api.name,
        accountNumber: api.accountNumber,
        createdBy: api.createdBy,
        createdAt: api.createdAt,
      );
      final existing = await _listsLocal.getListById(api.id);
      if (existing == null) {
        await _listsLocal.createList(local);
      } else {
        await _listsLocal.updateList(local);
      }
    }
  }
}
