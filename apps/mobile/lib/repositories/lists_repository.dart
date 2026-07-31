import 'package:drift/drift.dart';
import 'package:settl/database/database.dart';
import 'package:settl/models/list_model.dart';
import 'package:settl/models/list_member.dart';

class ListsRepository {
  final Database _db;

  ListsRepository(this._db);

  // Helper to get the drift database instance
  dynamic get _driftDb {
    return (_db as dynamic).instance;
  }

  Future<ListModel?> getListById(String listId) async {
    final result = await (_driftDb.lists)
        .where((tbl) => tbl.listId.equals(listId))
        .get()
        .first;

    return result.isNotEmpty ? ListModel.fromJson(result.first.toJson()) : null;
  }

  Future<List<ListModel>> getListsByUser(String userId) async {
    final result = await (_driftDb.lists)
        .where((tbl) => tbl.createdBy.equals(userId))
        .get();

    return result.map((row) => ListModel.fromJson(row.toJson())).toList();
  }

  Future<List<ListModel>> getAllLists() async {
    final result = await _driftDb.select(_driftDb.lists).get();
    return result.map((row) => ListModel.fromJson(row.toJson())).toList();
  }

  Future<void> createList(ListModel listModel) async {
    await _driftDb.into(_driftDb.lists).insert(listModel.toCompanion(true));
  }

  Future<void> updateList(ListModel listModel) async {
    await _driftDb.update(_driftDb.lists).replace(listModel.toCompanion(true));
  }

  Future<void> deleteList(String listId) async {
    await (_driftDb.lists)
        .where((tbl) => tbl.listId.equals(listId))
        .delete();
  }

  // List Members
  Future<void> addMemberToList(ListMember listMember) async {
    await _driftDb.into(_driftDb.listMembers).insert(listMember.toCompanion(true));
  }

  Future<List<ListMember>> getMembersOfList(String listId) async {
    final result = await (_driftDb.listMembers)
        .where((tbl) => tbl.listId.equals(listId))
        .get();

    return result.map((row) => ListMember.fromJson(row.toJson())).toList();
  }

  Future<void> removeMemberFromList(String listId, String participantId) async {
    await (_driftDb.listMembers)
        .where((tbl) => tbl.listId.equals(listId).and(tbl.participantId.equals(participantId)))
        .delete();
  }
}