import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Storage keys for authentication credentials.
///
/// Scope: credentials ONLY. Non-secret configuration (Supabase URL, anon key,
/// environment) intentionally stays in `AppEnvironment` — see T1.8 decision.
abstract final class SecureStorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
}

/// Stores authentication tokens in platform secure storage
/// (Android Keystore / iOS Keychain).
///
/// Used by the auth layer (Phase 6) to persist the session across app
/// restarts without exposing tokens to plaintext storage.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// Persists the access and refresh tokens.
  Future<void> storeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(
      key: SecureStorageKeys.accessToken,
      value: accessToken,
    );
    await _storage.write(
      key: SecureStorageKeys.refreshToken,
      value: refreshToken,
    );
  }

  /// Returns the stored access token, or null if none is stored.
  Future<String?> getAccessToken() async {
    return _storage.read(key: SecureStorageKeys.accessToken);
  }

  /// Returns the stored refresh token, or null if none is stored.
  Future<String?> getRefreshToken() async {
    return _storage.read(key: SecureStorageKeys.refreshToken);
  }

  /// Removes both tokens (e.g. on logout or when the session is revoked).
  Future<void> deleteTokens() async {
    await _storage.delete(key: SecureStorageKeys.accessToken);
    await _storage.delete(key: SecureStorageKeys.refreshToken);
  }
}

/// Provider for the secure token storage service
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
