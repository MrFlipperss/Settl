import 'package:settl/database/daos/lists_dao.dart';
import 'package:settl/models/collection_member.dart';
import 'package:settl/models/collection.dart';
import 'package:settl/repositories/interfaces/collection_repository.dart';

/// Drift-backed [CollectionRepository].
///
/// Delegates all persistence to [ListsDao]; no HTTP or schema knowledge
/// leaks into the UI layer.
class CollectionRepositoryImpl implements CollectionRepository {
  final ListsDao _dao;

  CollectionRepositoryImpl(this._dao);

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
  Future<void> updateCollection(Collection collection) =>
      _dao.updateCollection(collection);

  @override
  Future<void> deleteCollection(String collectionId) =>
      _dao.deleteCollection(collectionId);

  @override
  Future<void> addMemberToCollection(CollectionMember collectionMember) =>
      _dao.addMemberToCollection(collectionMember);

  @override
  Future<List<CollectionMember>> getMembersOfCollection(
          String collectionId) =>
      _dao.getMembersOfCollection(collectionId);

  @override
  Future<void> removeMemberFromCollection(
          String collectionId, String participantId) =>
      _dao.removeMemberFromCollection(collectionId, participantId);
}
