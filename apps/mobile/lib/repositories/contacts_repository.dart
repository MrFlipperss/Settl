import 'package:drift/drift.dart';
import 'package:settl/database/database.dart';
import 'package:settl/models/contact.dart';

class ContactsRepository {
  final Database _db;

  ContactsRepository(this._db);

  // Helper to get the drift database instance
  dynamic get _driftDb {
    return (_db as dynamic).instance;
  }

  Future<Contact?> getContactById(String participantId) async {
    final result = await (_driftDb.contacts)
        .where((tbl) => tbl.participantId.equals(participantId))
        .get()
        .first;

    return result.isNotEmpty ? Contact.fromJson(result.first.toJson()) : null;
  }

  Future<List<Contact>> getContactsByUser(String userId) async {
    final result = await (_driftDb.contacts)
        .where((tbl) => tbl.createdBy.equals(userId))
        .get();

    return result.map((row) => Contact.fromJson(row.toJson())).toList();
  }

  Future<List<Contact>> getAllContacts() async {
    final result = await _driftDb.select(_driftDb.contacts).get();
    return result.map((row) => Contact.fromJson(row.toJson())).toList();
  }

  Future<void> createContact(Contact contact) async {
    await _driftDb.into(_driftDb.contacts).insert(contact.toCompanion(true));
  }

  Future<void> updateContact(Contact contact) async {
    await _driftDb.update(_driftDb.contacts).replace(contact.toCompanion(true));
  }

  Future<void> deleteContact(String participantId) async {
    await (_driftDb.contacts)
        .where((tbl) => tbl.participantId.equals(participantId))
        .delete();
  }
}