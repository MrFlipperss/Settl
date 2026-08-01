import 'package:settl/database/daos/lists_dao.dart';
import 'package:settl/models/list_member.dart';
import 'package:settl/models/list_model.dart';
import 'package:settl/repositories/interfaces/collection_repository.dart';

/// Drift-backed [CollectionRepository].
///
/// Delegates all persistence to [ListsDao]; no HTTP or schema knowledge
/// leaks into the UI layer.
class CollectionRepositoryImpl implements CollectionRepository {
  final ListsDao _dao;

  CollectionRepositoryImpl(this._dao);

  @override
  Future<ListModel?> getListById(String listId) => _dao.getListById(listId);

  @override
  Future<List<ListModel>> getListsByUser(String userId) =>
      _dao.getListsByUser(userId);

  @override
  Future<List<ListModel>> getAllLists() => _dao.getAllLists();

  @override
  Future<void> createList(ListModel listModel) => _dao.createList(listModel);

  @override
  Future<void> updateList(ListModel listModel) => _dao.updateList(listModel);

  @override
  Future<void> deleteList(String listId) => _dao.deleteList(listId);

  @override
  Future<void> addMemberToList(ListMember listMember) =>
      _dao.addMemberToList(listMember);

  @override
  Future<List<ListMember>> getMembersOfList(String listId) =>
      _dao.getMembersOfList(listId);

  @override
  Future<void> removeMemberFromList(String listId, String participantId) =>
      _dao.removeMemberFromList(listId, participantId);
}
