import 'package:drift/drift.dart';

import '../app_database.dart';
import '../../models/pending_sync_operation.dart';

part 'pending_sync_dao.g.dart';

/// Offline-first mutation queue: enqueue writes locally, replay later.
@DriftAccessor(tables: [PendingSyncOperations])
class PendingSyncDao extends DatabaseAccessor<AppDatabase>
    with _$PendingSyncDaoMixin {
  PendingSyncDao(super.db);

  Future<void> enqueue(PendingSyncOperation operation) async {
    await into(pendingSyncOperations).insert(
      PendingSyncOperationsCompanion.insert(
        operationId: operation.operationId,
        entityType: operation.entityType,
        entityId: operation.entityId,
        operation: operation.operation.name,
        payload: operation.payload,
        createdAt: operation.createdAt,
      ),
    );
  }

  /// Operations not yet confirmed synced, oldest first.
  Future<List<PendingSyncOperation>> getPending() async {
    final rows = await (select(pendingSyncOperations)
          ..where((tbl) => tbl.syncedAt.isNull())
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .get();
    return rows.map(_fromRow).toList();
  }

  /// Operations still eligible for replay: never confirmed synced AND with
  /// attempts remaining (`attemptCount < maxAttempts`), oldest first (T8.3).
  ///
  /// Permanently failed operations (see [getFailed]) are excluded so they
  /// cannot block the FIFO drain.
  Future<List<PendingSyncOperation>> getPendingRetryable(int maxAttempts) async {
    final rows = await (select(pendingSyncOperations)
          ..where((tbl) =>
              tbl.syncedAt.isNull() &
              tbl.attemptCount.isSmallerThanValue(maxAttempts))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .get();
    return rows.map(_fromRow).toList();
  }

  /// All operations, newest first (for diagnostics).
  Future<List<PendingSyncOperation>> getAll() async {
    final rows = await (select(pendingSyncOperations)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<void> markSynced(String operationId, DateTime syncedAt) async {
    await (update(pendingSyncOperations)
          ..where((tbl) => tbl.operationId.equals(operationId)))
        .write(PendingSyncOperationsCompanion(syncedAt: Value(syncedAt)));
  }

  /// Records a failed replay attempt: bumps [PendingSyncOperations.attemptCount]
  /// and stores [error] as [PendingSyncOperations.lastError] (T8.4).
  Future<void> markFailed(
    String operationId, {
    required int attemptCount,
    required String error,
  }) async {
    await (update(pendingSyncOperations)
          ..where((tbl) => tbl.operationId.equals(operationId)))
        .write(PendingSyncOperationsCompanion(
      attemptCount: Value(attemptCount),
      lastError: Value(error),
    ));
  }

  /// Operations whose attempts have been exhausted (never confirmed synced),
  /// oldest first — the "permanently failed" view for diagnostics / UI.
  Future<List<PendingSyncOperation>> getFailed(int maxAttempts) async {
    final rows = await (select(pendingSyncOperations)
          ..where((tbl) =>
              tbl.syncedAt.isNull() & tbl.attemptCount.isBiggerOrEqualValue(
                  maxAttempts))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<void> deleteOperation(String operationId) async {
    await (delete(pendingSyncOperations)
          ..where((tbl) => tbl.operationId.equals(operationId)))
        .go();
  }

  Future<void> clearSynced() async {
    await (delete(pendingSyncOperations)
          ..where((tbl) => tbl.syncedAt.isNotNull()))
        .go();
  }

  Future<int> pendingCount() async {
    final count = await (selectOnly(pendingSyncOperations)
          ..addColumns([
            pendingSyncOperations.operationId.count(),
          ])
          ..where(pendingSyncOperations.syncedAt.isNull()))
        .getSingle();
    return count.read(pendingSyncOperations.operationId.count()) ?? 0;
  }

  PendingSyncOperation _fromRow(PendingSyncOperationRow row) =>
      PendingSyncOperation(
        operationId: row.operationId,
        entityType: row.entityType,
        entityId: row.entityId,
        operation: SyncOperation.values.byName(row.operation),
        payload: row.payload,
        createdAt: row.createdAt,
        syncedAt: row.syncedAt,
        attemptCount: row.attemptCount,
        lastError: row.lastError,
      );
}
