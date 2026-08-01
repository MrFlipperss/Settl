import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settl/models/profile.dart';
import 'package:settl/services/http_client_service.dart';

/// Example repository showing how to use the HTTP client service
class ProfileApiRepository {
  final HttpClientService _httpClient;

  ProfileApiRepository(this._httpClient);

  Future<Profile?> fetchProfile(String userId) async {
    try {
      final response = await _httpClient.getJson<Map<String, dynamic>>(
        'profiles/$userId',
        fromJson: (json) => Profile.fromJson(json),
      );
      return response;
    } catch (e) {
      // In a real app, you might want to handle different types of errors differently
      rethrow;
    }
  }

  Future<Profile> updateProfile(Profile profile) async {
    try {
      final response = await _httpClient.put<Map<String, dynamic>>(
        'profiles/${profile.id}',
        body: profile.toJson(),
        fromJson: (json) => Profile.fromJson(json),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for the profile API repository
final profileApiRepositoryProvider = Provider<ProfileApiRepository>((ref) {
  final httpClient = ref.read(httpClientServiceProvider);
  return ProfileApiRepository(httpClient);
});