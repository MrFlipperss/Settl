import 'package:settl/api/contacts_api.dart';
import 'package:settl/database/daos/contacts_dao.dart';
import 'package:settl/models/contact.dart';
import 'package:settl/repositories/interfaces/contact_repository.dart';

/// Drift-backed [ContactRepository] with a remote claim seam.
///
/// Delegates local persistence to [ContactsDao] and remote contact claiming to
/// [ContactsApi]; no schema or HTTP knowledge leaks into the UI layer.
class ContactRepositoryImpl implements ContactRepository {
  final ContactsDao _dao;
  final ContactsApi _api;

  ContactRepositoryImpl(this._dao, this._api);

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

  @override
  Future<int> claimContacts(String phoneNumber) =>
      _api.claimContacts(phoneNumber);
}
