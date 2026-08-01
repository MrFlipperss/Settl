import '../../models/auth_session.dart';

/// Contract for authentication with the Supabase backend (phone OTP flow).
///
/// The UI and services depend on this interface only — never on Supabase or
/// gotrue types directly.
abstract class AuthRepository {
  /// The current session, or null when signed out.
  AuthSession? get currentSession;

  /// Emits the session whenever it changes (sign-in, sign-out, token
  /// refresh).
  Stream<AuthSession?> get onAuthStateChanged;

  /// Sends a one-time password to [phone] (E.164). Completes when the SMS
  /// is dispatched.
  Future<void> sendOtp(String phone);

  /// Verifies [token] received on [phone] and returns the resulting session.
  Future<AuthSession> verifyOtp({
    required String phone,
    required String token,
  });

  /// Restores a persisted session (e.g. on app start). Returns null when the
  /// user is signed out.
  Future<AuthSession?> restoreSession();

  /// Refreshes the access token using the stored refresh token (T6.6).
  Future<AuthSession> refreshSession();

  /// Signs out locally and clears the persisted session.
  Future<void> signOut();
}
