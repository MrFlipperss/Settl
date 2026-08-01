import 'package:settl/models/list_member.dart';
import 'package:settl/models/list_model.dart';

/// Contract for collection (list) + membership persistence.
///
/// Implementations back the UI with local storage (Drift DAOs) or, once the
/// sync layer lands, a remote API. The UI and services depend on this
/// interface only — never on HTTP or database details.
abstract class CollectionRepository {
  Future<ListModel?> getListById(String listId);

  Future<List<ListModel>> getListsByUser(String userId);

  Future<List<ListModel>> getAllLists();

  Future<void> createList(ListModel listModel);

  Future<void> updateList(ListModel listModel);

  /// Deletes the list and all of its memberships.
  Future<void> deleteList(String listId);

  Future<void> addMemberToList(ListMember listMember);

  Future<List<ListMember>> getMembersOfList(String listId);

  Future<void> removeMemberFromList(String listId, String participantId);
}
