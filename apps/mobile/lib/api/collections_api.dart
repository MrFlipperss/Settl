import 'api_client.dart';
import 'models/api_collection.dart';
import 'models/api_requests.dart';

/// T7.3 — Collections (groups) API.
///
/// The backend routes live under `/api/v1/groups`; the domain term in the app
/// is "collections". Includes membership management.
class CollectionsApi {
  CollectionsApi(this._client);

  final ApiClient _client;

  /// Creates a new collection (201). The creator is added as a member
  /// server-side.
  Future<ApiCollection> createCollection(
    ApiCreateCollectionRequest request,
  ) async {
    final json = await _client.post('v1/groups/', body: request.toJson());
    return ApiCollection.fromJson(json as Map<String, dynamic>);
  }

  /// Lists collections the authenticated user belongs to.
  Future<List<ApiCollection>> listCollections() async {
    final json = await _client.get('v1/groups/');
    return (json as List)
        .map((e) => ApiCollection.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches a single collection by id. Throws [ApiException] (403/404) when
  /// the user is not a member or the collection does not exist.
  Future<ApiCollection> getCollection(String groupId) async {
    final json = await _client.get('v1/groups/$groupId');
    return ApiCollection.fromJson(json as Map<String, dynamic>);
  }

  /// Adds [participantId] as a member of [groupId] (201, empty body).
  Future<void> addMember(String groupId, String participantId) async {
    await _client.post(
      'v1/groups/$groupId/members',
      body: ApiAddMemberRequest(userId: participantId).toJson(),
    );
  }
}
