import '../../models/auth_session.dart';

/// Contract for authentication with the Supabase backend.
///
/// Supports both phone OTP and email/password authentication flows.
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

  /// Signs in with email and password.
  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  });

  /// Signs up with email and password.
  Future<AuthSession> signUpWithEmail({
    required String email,
    required String password,
    required Map<String, dynamic> data,
  });

  /// Sends a password reset email to [email].
  Future<void> sendPasswordResetEmail(String email);

  /// Restores a persisted session (e.g. on app start). Returns null when the
  /// user is signed out.
  Future<AuthSession?> restoreSession();

  /// Refreshes the access token using the stored refresh token (T6.6).
  Future<AuthSession> refreshSession();

  /// Signs out locally and clears the persisted session.
  Future<void> signOut();
}
