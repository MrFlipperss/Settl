import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../api/models/api_requests.dart';
import '../database/daos/pending_sync_dao.dart';
import '../models/pending_sync_operation.dart';

/// Offline-first mutation queue facade (T8.2).
///
/// Enqueues local writes as [PendingSyncOperation] rows whose [payload] is the
/// snake_case wire JSON of the matching request DTO, so [PushWorker] can replay
/// them to the backend unchanged. When the DTO carries no id, the queue
/// generates one and bakes it into the payload — keeping
/// [PendingSyncOperation.entityId] and the replayed request id in sync, which
/// is what makes retries idempotent.
class SyncQueue {
  SyncQueue(this._dao, {String Function()? idGenerator})
      : _idGenerator = idGenerator ?? _uuid.v4;

  static const _uuid = Uuid();

  final PendingSyncDao _dao;
  final String Function() _idGenerator;

  static const entityExpense = 'expense';
  static const entityContact = 'contact';
  static const entityCollection = 'collection';
  static const entityProfile = 'profile';

  Future<void> enqueueExpense({
    required SyncOperation operation,
    required ApiCreateExpenseRequest request,
  }) async {
    final entityId = request.id ?? _idGenerator();
    final payloadRequest = request.id == null
        ? ApiCreateExpenseRequest(
            id: entityId,
            groupId: request.groupId,
            payerId: request.payerId,
            amount: request.amount,
            splitType: request.splitType,
            category: request.category,
            note: request.note,
            idempotencyKey: request.idempotencyKey,
            timestamp: request.timestamp,
            splits: request.splits,
          )
        : request;
    await _enqueue(
      entityType: entityExpense,
      entityId: entityId,
      operation: operation,
      payload: payloadRequest.toJson(),
    );
  }

  Future<void> enqueueContact({
    required SyncOperation operation,
    required ApiCreateContactRequest request,
  }) async {
    final entityId = request.id ?? _idGenerator();
    final payloadRequest = request.id == null
        ? ApiCreateContactRequest(
            id: entityId,
            displayName: request.displayName,
            phoneNumber: request.phoneNumber,
          )
        : request;
    await _enqueue(
      entityType: entityContact,
      entityId: entityId,
      operation: operation,
      payload: payloadRequest.toJson(),
    );
  }

  Future<void> enqueueCollection({
    required SyncOperation operation,
    required ApiCreateCollectionRequest request,
  }) async {
    final entityId = request.id ?? _idGenerator();
    final payloadRequest = request.id == null
        ? ApiCreateCollectionRequest(
            id: entityId,
            name: request.name,
            currency: request.currency,
          )
        : request;
    await _enqueue(
      entityType: entityCollection,
      entityId: entityId,
      operation: operation,
      payload: payloadRequest.toJson(),
    );
  }

  /// Queues a profile upsert. The backend `POST /v1/profile` is idempotent, so
  /// [operation] is always [SyncOperation.insert] and [entityId] is the
  /// caller's participant id.
  Future<void> enqueueProfile({
    required String entityId,
    required ApiCreateProfileRequest request,
  }) async {
    await _enqueue(
      entityType: entityProfile,
      entityId: entityId,
      operation: SyncOperation.insert,
      payload: request.toJson(),
    );
  }

  Future<void> _enqueue({
    required String entityType,
    required String entityId,
    required SyncOperation operation,
    required Map<String, dynamic> payload,
  }) async {
    await _dao.enqueue(PendingSyncOperation(
      operationId: _idGenerator(),
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payload: jsonEncode(payload),
      createdAt: DateTime.now(),
    ));
  }
}
