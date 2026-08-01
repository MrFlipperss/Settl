import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A [LocalStorage] implementation backed by platform secure storage
/// (Android Keystore / iOS Keychain), honoring the T1.8 decision that
/// credentials live only in secure storage — never SharedPreferences.
///
/// Passed to `Supabase.initialize` via `FlutterAuthClientOptions` so the
/// Supabase session survives app restarts without leaking tokens to
/// plaintext storage.
class SupabaseSecureStorage extends LocalStorage {
  SupabaseSecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// Key under which the serialized session is stored.
  static const _sessionKey = 'supabase_session';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async =>
      (await _storage.read(key: _sessionKey)) != null;

  @override
  Future<String?> accessToken() => _storage.read(key: _sessionKey);

  @override
  Future<void> removePersistedSession() =>
      _storage.delete(key: _sessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _sessionKey, value: persistSessionString);
}
