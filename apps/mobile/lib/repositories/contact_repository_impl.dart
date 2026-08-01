import 'package:settl/database/daos/contacts_dao.dart';
import 'package:settl/models/contact.dart';
import 'package:settl/repositories/interfaces/contact_repository.dart';

/// Drift-backed [ContactRepository].
///
/// Delegates all persistence to [ContactsDao]; no HTTP or schema knowledge
/// leaks into the UI layer.
class ContactRepositoryImpl implements ContactRepository {
  final ContactsDao _dao;

  ContactRepositoryImpl(this._dao);

  @override
  Future<Contact?> getContactById(String participantId) =>
      _dao.getContactById(participantId);

  @override
  Future<List<Contact>> getContactsByUser(String userId) =>
      _dao.getContactsByUser(userId);

  @override
  Future<List<Contact>> getAllContacts() => _dao.getAllContacts();

  @override
  Future<void> createContact(Contact contact) => _dao.createContact(contact);

  @override
  Future<void> updateContact(Contact contact) => _dao.updateContact(contact);

  @override
  Future<void> deleteContact(String participantId) =>
      _dao.deleteContact(participantId);
}
