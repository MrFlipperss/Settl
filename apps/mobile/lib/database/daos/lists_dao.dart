import 'package:drift/drift.dart';

import '../app_database.dart';
import '../../models/collection_member.dart';
import '../../models/collection.dart';

part 'lists_dao.g.dart';

/// CRUD access to the [Lists] and [ListMembers] tables, mapped to
/// [Collection]/[CollectionMember] domain models.
@DriftAccessor(tables: [Lists, ListMembers])
class ListsDao extends DatabaseAccessor<AppDatabase> with _$ListsDaoMixin {
  ListsDao(super.db);

  Future<Collection?> getCollectionById(String collectionId) async {
    final row = await (select(lists)..where((tbl) => tbl.listId.equals(collectionId)))
        .getSingleOrNull();
    return row == null ? null : _collectionFromRow(row);
  }

  Future<List<Collection>> getCollectionsByUser(String userId) async {
    final rows = await (select(lists)
          ..where((tbl) => tbl.createdBy.equals(userId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .get();
    return rows.map(_collectionFromRow).toList();
  }

  Future<List<Collection>> getAllCollections() async {
    final rows = await (select(lists)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .get();
    return rows.map(_collectionFromRow).toList();
  }

  Future<void> createCollection(Collection collection) async {
    await into(lists).insert(ListsCompanion.insert(
      listId: collection.id,
      name: collection.name,
      accountNumber: collection.accountNumber,
      createdBy: collection.createdBy,
      createdAt: collection.createdAt,
    ));
  }

  Future<void> updateCollection(Collection collection) async {
    await (update(lists)..where((tbl) => tbl.listId.equals(collection.id)))
        .write(ListsCompanion(
      name: Value(collection.name),
      accountNumber: Value(collection.accountNumber),
    ));
  }

  Future<void> deleteCollection(String collectionId) async {
    await (delete(lists)..where((tbl) => tbl.listId.equals(collectionId))).go();
    await (delete(listMembers)
          ..where((tbl) => tbl.listId.equals(collectionId)))
        .go();
  }

  // -- Collection members ---------------------------------------------------

  Future<void> addMemberToCollection(CollectionMember collectionMember) async {
    await into(listMembers).insert(ListMembersCompanion.insert(
      listId: collectionMember.collectionId,
      participantId: collectionMember.participantId,
      addedAt: collectionMember.addedAt,
    ));
  }

  Future<List<CollectionMember>> getMembersOfCollection(
      String collectionId) async {
    final rows = await (select(listMembers)
          ..where((tbl) => tbl.listId.equals(collectionId)))
        .get();
    return rows.map(_memberFromRow).toList();
  }

  Future<void> removeMemberFromCollection(
      String collectionId, String participantId) async {
    await (delete(listMembers)
          ..where((tbl) =>
              tbl.listId.equals(collectionId) &
              tbl.participantId.equals(participantId)))
        .go();
  }

  // -- Mappers --------------------------------------------------------------

  Collection _collectionFromRow(ListRow row) => Collection(
        id: row.listId,
        name: row.name,
        accountNumber: row.accountNumber,
        createdBy: row.createdBy,
        createdAt: row.createdAt,
      );

  CollectionMember _memberFromRow(ListMemberRow row) => CollectionMember(
        collectionId: row.listId,
        participantId: row.participantId,
        addedAt: row.addedAt,
      );
}
