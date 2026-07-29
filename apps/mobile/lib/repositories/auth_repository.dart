import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthResponse, OtpType, SupabaseClient, User;
import '../database/database.dart';

class AuthRepository {
  final Database _db;

  AuthRepository(this._db);

  SupabaseClient get _client => _db.client;

  User? get currentUser => _client.auth.currentUser;

  bool get isAuthenticated => currentUser != null;

  Future<void> signInWithOtp(String phone) async {
    await _client.auth.signInWithOtp(phone: phone);
  }

  Future<AuthResponse> verifyOtp({
    required String phone,
    required String token,
    OtpType type = OtpType.sms,
  }) {
    return _client.auth.verifyOTP(phone: phone, token: token, type: type);
  }

  Future<AuthResponse> signInAnonymously() {
    return _client.auth.signInAnonymously();
  }

  Future<void> signOut() => _client.auth.signOut();
}
