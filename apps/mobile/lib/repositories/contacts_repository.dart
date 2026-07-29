import '../database/database.dart';
import '../models/contact.dart';

class ContactsRepository {
  final Database _db;

  ContactsRepository(this._db);

  Future<List<Contact>> getContacts() async {
    final response = await _db.client.from('contacts').select();
    return response.map((json) => Contact.fromJson(json)).toList();
  }

  Future<Contact> createContact(Contact contact) async {
    final response = await _db.client
        .from('contacts')
        .insert(contact.toJson())
        .select()
        .single();
    return Contact.fromJson(response);
  }
}
