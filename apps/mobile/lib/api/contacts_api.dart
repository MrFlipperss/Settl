import 'api_client.dart';
import 'models/api_contact.dart';
import 'models/api_contact_search_result.dart';
import 'models/api_requests.dart';

/// T7.2 — Contacts API.
///
/// Mirrors the backend contact handlers: create an ad-hoc contact, search the
/// global contact table, and claim unclaimed contacts matching the signed-in
/// user's phone number.
class ContactsApi {
  ContactsApi(this._client);

  final ApiClient _client;

  /// Creates a new ad-hoc contact (201).
  Future<ApiContact> createContact(ApiCreateContactRequest request) async {
    final json = await _client.post('v1/contacts', body: request.toJson());
    return ApiContact.fromJson(json as Map<String, dynamic>);
  }

  /// Searches contacts by name or phone number substring.
  Future<List<ApiContactSearchResult>> searchContacts(String query) async {
    final json = await _client.get('v1/contacts/search', query: {'q': query});
    return (json as List)
        .map((e) => ApiContactSearchResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Claims any unclaimed contacts matching [phoneNumber]; returns the number
  /// of contacts claimed.
  Future<int> claimContacts(String phoneNumber) async {
    final json = await _client.post(
      'v1/contacts/claim',
      body: ApiClaimContactsRequest(phoneNumber: phoneNumber).toJson(),
    );
    return (json as Map<String, dynamic>)['claimed'] as int;
  }
}
