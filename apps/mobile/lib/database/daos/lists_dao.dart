import 'package:drift/drift.dart';

import '../app_database.dart';
import '../../models/list_member.dart';
import '../../models/list_model.dart';

part 'lists_dao.g.dart';

/// CRUD access to [Lists] and [ListMembers], mapped to domain models.
@DriftAccessor(tables: [Lists, ListMembers])
class ListsDao extends DatabaseAccessor<AppDatabase> with _$ListsDaoMixin {
  ListsDao(super.db);

  Future<ListModel?> getListById(String listId) async {
    final row = await (select(lists)..where((tbl) => tbl.listId.equals(listId)))
        .getSingleOrNull();
    return row == null ? null : _listFromRow(row);
  }

  Future<List<ListModel>> getListsByUser(String userId) async {
    final rows = await (select(lists)
          ..where((tbl) => tbl.createdBy.equals(userId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .get();
    return rows.map(_listFromRow).toList();
  }

  Future<List<ListModel>> getAllLists() async {
    final rows = await (select(lists)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .get();
    return rows.map(_listFromRow).toList();
  }

  Future<void> createList(ListModel listModel) async {
    await into(lists).insert(ListsCompanion.insert(
      listId: listModel.id,
      name: listModel.name,
      accountNumber: listModel.accountNumber,
      createdBy: listModel.createdBy,
      createdAt: listModel.createdAt,
    ));
  }

  Future<void> updateList(ListModel listModel) async {
    await (update(lists)..where((tbl) => tbl.listId.equals(listModel.id)))
        .write(ListsCompanion(
      name: Value(listModel.name),
      accountNumber: Value(listModel.accountNumber),
    ));
  }

  Future<void> deleteList(String listId) async {
    await (delete(lists)..where((tbl) => tbl.listId.equals(listId))).go();
    await (delete(listMembers)
          ..where((tbl) => tbl.listId.equals(listId)))
        .go();
  }

  // -- List members ---------------------------------------------------------

  Future<void> addMemberToList(ListMember listMember) async {
    await into(listMembers).insert(ListMembersCompanion.insert(
      listId: listMember.listId,
      participantId: listMember.participantId,
      addedAt: listMember.addedAt,
    ));
  }

  Future<List<ListMember>> getMembersOfList(String listId) async {
    final rows = await (select(listMembers)
          ..where((tbl) => tbl.listId.equals(listId)))
        .get();
    return rows.map(_memberFromRow).toList();
  }

  Future<void> removeMemberFromList(String listId, String participantId) async {
    await (delete(listMembers)
          ..where((tbl) =>
              tbl.listId.equals(listId) & tbl.participantId.equals(participantId)))
        .go();
  }

  // -- Mappers --------------------------------------------------------------

  ListModel _listFromRow(ListRow row) => ListModel(
        id: row.listId,
        name: row.name,
        accountNumber: row.accountNumber,
        createdBy: row.createdBy,
        createdAt: row.createdAt,
      );

  ListMember _memberFromRow(ListMemberRow row) => ListMember(
        listId: row.listId,
        participantId: row.participantId,
        addedAt: row.addedAt,
      );
}
