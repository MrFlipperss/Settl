import 'package:uuid/uuid.dart';

import 'package:settl/api/models/api_requests.dart';
import 'package:settl/database/daos/lists_dao.dart';
import 'package:settl/models/collection_member.dart';
import 'package:settl/models/collection.dart';
import 'package:settl/repositories/interfaces/collection_repository.dart';
import 'package:settl/models/pending_sync_operation.dart';
import 'package:settl/sync/sync_queue.dart';

/// Drift-backed [CollectionRepository].
///
/// Delegates all persistence to [ListsDao]; no HTTP or schema knowledge
/// leaks into the UI layer.
class CollectionRepositoryImpl implements CollectionRepository {
  final ListsDao _dao;
  final SyncQueue? _syncQueue;

  CollectionRepositoryImpl(this._dao, [this._syncQueue]);

  static const _pendingAccountNumber = 'PENDING';
  static const _uuid = Uuid();

  @override
  Future<Collection?> getCollectionById(String collectionId) =>
      _dao.getCollectionById(collectionId);

  @override
  Future<List<Collection>> getCollectionsByUser(String userId) =>
      _dao.getCollectionsByUser(userId);

  @override
  Future<List<Collection>> getAllCollections() => _dao.getAllCollections();

  @override
  Future<void> createCollection(Collection collection) =>
      _dao.createCollection(collection);

  @override
  Future<Collection> createCollectionForParticipant({
    required String name,
    required String participantId,
  }) async {
    final trimmedName = name.trim();
    final trimmedParticipantId = participantId.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Group name cannot be empty.');
    }
    if (trimmedParticipantId.isEmpty) {
      throw ArgumentError('A signed-in participant is required.');
    }
    final syncQueue = _syncQueue;
    if (syncQueue == null) {
      throw StateError('Group creation is not available in this repository.');
    }

    final collection = Collection(
      id: _uuid.v4(),
      name: trimmedName,
      accountNumber: _pendingAccountNumber,
      createdBy: trimmedParticipantId,
      createdAt: DateTime.now(),
    );
    try {
      await _dao.createCollection(collection);
      await _dao.addMemberToCollection(CollectionMember(
        collectionId: collection.id,
        participantId: trimmedParticipantId,
        addedAt: collection.createdAt,
      ));
      await syncQueue.enqueueCollection(
        operation: SyncOperation.insert,
        request: ApiCreateCollectionRequest(
          id: collection.id,
          name: collection.name,
        ),
      );
    } catch (_) {
      await _dao.deleteCollection(collection.id);
      rethrow;
    }
    return collection;
  }

  @override
  Future<void> updateCollection(Collection collection) =>
      _dao.updateCollection(collection);

  @override
  Future<void> deleteCollection(String collectionId) =>
      _dao.deleteCollection(collectionId);

  @override
  Future<void> addMemberToCollection(CollectionMember collectionMember) async {
    await _dao.addMemberToCollection(collectionMember);
    final syncQueue = _syncQueue;
    if (syncQueue == null) return;
    try {
      await syncQueue.enqueueCollectionMember(
          operation: SyncOperation.insert,
          collectionId: collectionMember.collectionId,
          participantId: collectionMember.participantId);
    } catch (_) {
      await _dao.removeMemberFromCollection(
          collectionMember.collectionId, collectionMember.participantId);
      rethrow;
    }
  }

  @override
  Future<List<CollectionMember>> getMembersOfCollection(String collectionId) =>
      _dao.getMembersOfCollection(collectionId);

  @override
  Future<void> removeMemberFromCollection(
      String collectionId, String participantId) async {
    await _dao.removeMemberFromCollection(collectionId, participantId);
    final syncQueue = _syncQueue;
    if (syncQueue == null) return;
    try {
      await syncQueue.enqueueCollectionMember(
        operation: SyncOperation.delete,
        collectionId: collectionId,
        participantId: participantId,
      );
    } catch (_) {
      await _dao.addMemberToCollection(CollectionMember(
        collectionId: collectionId,
        participantId: participantId,
        addedAt: DateTime.now(),
      ));
      rethrow;
    }
  }
}
