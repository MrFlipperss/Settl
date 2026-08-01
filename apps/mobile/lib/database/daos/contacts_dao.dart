import 'package:drift/drift.dart';

import '../app_database.dart';
import '../../models/contact.dart';

part 'contacts_dao.g.dart';

/// CRUD access to [Contacts], mapped to the [Contact] domain model.
@DriftAccessor(tables: [Contacts])
class ContactsDao extends DatabaseAccessor<AppDatabase>
    with _$ContactsDaoMixin {
  ContactsDao(super.db);

  Future<Contact?> getContactById(String participantId) async {
    final row = await (select(contacts)
          ..where((tbl) => tbl.participantId.equals(participantId)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<List<Contact>> getContactsByUser(String userId) async {
    final rows = await (select(contacts)
          ..where((tbl) => tbl.createdBy.equals(userId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.displayName)]))
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<List<Contact>> getAllContacts() async {
    final rows = await (select(contacts)
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.displayName)]))
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<void> createContact(Contact contact) async {
    await into(contacts).insert(ContactsCompanion.insert(
      participantId: contact.participantId,
      phoneNumber: contact.phoneNumber,
      displayName: contact.displayName,
      createdBy: contact.createdBy,
      claimedByParticipantId: Value(contact.claimedByParticipantId),
      createdAt: contact.createdAt,
    ));
  }

  Future<void> updateContact(Contact contact) async {
    await (update(contacts)
          ..where((tbl) => tbl.participantId.equals(contact.participantId)))
        .write(ContactsCompanion(
      phoneNumber: Value(contact.phoneNumber),
      displayName: Value(contact.displayName),
      createdBy: Value(contact.createdBy),
      claimedByParticipantId: Value(contact.claimedByParticipantId),
    ));
  }

  Future<void> deleteContact(String participantId) async {
    await (delete(contacts)
          ..where((tbl) => tbl.participantId.equals(participantId)))
        .go();
  }

  Contact _fromRow(ContactRow row) => Contact(
        participantId: row.participantId,
        phoneNumber: row.phoneNumber,
        displayName: row.displayName,
        createdBy: row.createdBy,
        claimedByParticipantId: row.claimedByParticipantId,
        createdAt: row.createdAt,
      );
}
