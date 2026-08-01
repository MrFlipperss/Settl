import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthState, GoTrueClient, OtpType, Session;

import '../models/auth_session.dart';
import 'interfaces/auth_repository.dart';

/// Supabase-backed [AuthRepository] using the phone OTP flow.
///
/// Wraps a gotrue [GoTrueClient] and maps gotrue [Session] objects to the
/// domain [AuthSession] so callers never depend on Supabase types.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._auth, {bool listenToAuthState = true}) {
    if (listenToAuthState) _startListening();
  }

  final GoTrueClient _auth;

  final StreamController<AuthSession?> _controller =
      StreamController<AuthSession?>.broadcast();
  StreamSubscription<AuthState>? _sub;

  @override
  AuthSession? get currentSession => _toSession(_auth.currentSession);

  @override
  Stream<AuthSession?> get onAuthStateChanged => _controller.stream;

  void _startListening() {
    _sub ??= _auth.onAuthStateChange.listen((state) {
      _controller.add(_toSession(state.session));
    });
  }

  @override
  Future<void> sendOtp(String phone) async {
    await _auth.signInWithOtp(phone: phone);
  }

  @override
  Future<AuthSession> verifyOtp({
    required String phone,
    required String token,
  }) async {
    final response = await _auth.verifyOTP(
      type: OtpType.sms,
      token: token,
      phone: phone,
    );
    final session = response.session;
    if (session == null) {
      throw StateError('OTP verified but no session was returned.');
    }
    return _toSession(session)!;
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final session = _auth.currentSession;
    return _toSession(session);
  }

  @override
  Future<AuthSession> refreshSession() async {
    final response = await _auth.refreshSession();
    final session = response.session;
    if (session == null) {
      throw StateError('Token refresh returned no session.');
    }
    return _toSession(session)!;
  }

  @override
  Future<void> signOut() => _auth.signOut();

  /// Maps a gotrue [Session] to a domain [AuthSession]; null when signed out.
  AuthSession? _toSession(Session? session) {
    if (session == null) return null;
    final user = session.user;
    return AuthSession(
      userId: user.id,
      phoneNumber: user.phone,
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      expiresAt: session.expiresAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000),
    );
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
