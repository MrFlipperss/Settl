import 'api_client.dart';
import 'models/api_profile.dart';
import 'models/api_requests.dart';

/// T7.1 — Profile API.
///
/// The backend `POST /api/v1/profile` is idempotent: it returns the existing
/// profile (200) when one already exists for the authenticated user, or
/// creates and returns a new one (201). It is deliberately NOT behind
/// AuthMiddleware (a brand-new signup has no profile row yet) but still
/// requires a valid Supabase access token.
class ProfileApi {
  ProfileApi(this._client);

  final ApiClient _client;

  /// Creates (or returns the existing) profile for the authenticated user.
  Future<ApiProfile> createProfile(ApiCreateProfileRequest request) async {
    final json = await _client.post('v1/profile', body: request.toJson());
    return ApiProfile.fromJson(json as Map<String, dynamic>);
  }
}
