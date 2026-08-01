import 'package:settl/models/contact.dart';

/// Contract for contact persistence.
///
/// Implementations back the UI with local storage (Drift DAOs) or, once the
/// sync layer lands, a remote API. The UI and services depend on this
/// interface only — never on HTTP or database details.
abstract class ContactRepository {
  Future<Contact?> getContactById(String participantId);

  Future<List<Contact>> getContactsByUser(String userId);

  Future<List<Contact>> getAllContacts();

  Future<void> createContact(Contact contact);

  Future<void> updateContact(Contact contact);

  Future<void> deleteContact(String participantId);
}
