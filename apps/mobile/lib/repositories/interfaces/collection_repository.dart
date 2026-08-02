import 'package:settl/models/collection_member.dart';
import 'package:settl/models/collection.dart';

/// Contract for collection + membership persistence.
///
/// Implementations back the UI with local storage (Drift DAOs) or, once the
/// sync layer lands, a remote API. The UI and services depend on this
/// interface only — never on HTTP or database details.
abstract class CollectionRepository {
  Future<Collection?> getCollectionById(String collectionId);

  Future<List<Collection>> getCollectionsByUser(String userId);

  Future<List<Collection>> getAllCollections();

  Future<void> createCollection(Collection collection);

  Future<void> updateCollection(Collection collection);

  /// Deletes the collection and all of its memberships.
  Future<void> deleteCollection(String collectionId);

  Future<void> addMemberToCollection(CollectionMember collectionMember);

  Future<List<CollectionMember>> getMembersOfCollection(String collectionId);

  Future<void> removeMemberFromCollection(
      String collectionId, String participantId);
}
