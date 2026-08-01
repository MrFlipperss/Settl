import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/auth_session.dart';
import '../models/profile.dart';
import '../repositories/interfaces/auth_repository.dart';
import '../repositories/interfaces/profile_repository.dart';
import '../utils/phone_utils.dart';

/// Application-facing authentication facade.
///
/// Normalizes phone numbers to E.164, delegates to [AuthRepository], and
/// surfaces results as [AsyncValue]s ready for Riverpod widgets. Also
/// bootstraps a local [Profile] row for the signed-in user (T6.5).
class AuthService {
  AuthService({
    required AuthRepository authRepository,
    required ProfileRepository profileRepository,
  })  : _authRepository = authRepository,
        _profileRepository = profileRepository;

  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;
  static const _uuid = Uuid();

  bool get isAuthenticated => _authRepository.currentSession != null;

  AuthSession? get currentSession => _authRepository.currentSession;

  Stream<AuthSession?> get onAuthStateChanged =>
      _authRepository.onAuthStateChanged;

  /// Sends a one-time password to [rawPhone] after E.164 normalization.
  Future<AsyncValue<void>> signInWithPhone(String rawPhone) async {
    final phone = normalizePhone(rawPhone);
    if (phone == null) {
      return AsyncValue.error(
        ArgumentError('Invalid phone number: $rawPhone'),
        StackTrace.current,
      );
    }
    try {
      await _authRepository.sendOtp(phone);
      return const AsyncValue.data(null);
    } catch (error, stackTrace) {
      return AsyncValue.error(error, stackTrace);
    }
  }

  /// Verifies [token] received on [rawPhone] and returns the new session.
  ///
  /// On success, ensures a local [Profile] row exists for the user (T6.5).
  Future<AsyncValue<AuthSession>> verifyOtp({
    required String rawPhone,
    required String token,
  }) async {
    final phone = normalizePhone(rawPhone);
    if (phone == null) {
      return AsyncValue.error(
        ArgumentError('Invalid phone number: $rawPhone'),
        StackTrace.current,
      );
    }
    try {
      final session = await _authRepository.verifyOtp(
        phone: phone,
        token: token,
      );
      await _bootstrapProfile(session);
      return AsyncValue.data(session);
    } catch (error, stackTrace) {
      return AsyncValue.error(error, stackTrace);
    }
  }

  /// Restores a persisted session (e.g. on app start). Returns null when the
  /// user is signed out.
  Future<AsyncValue<AuthSession?>> restoreSession() async {
    try {
      return AsyncValue.data(await _authRepository.restoreSession());
    } catch (error, stackTrace) {
      return AsyncValue.error(error, stackTrace);
    }
  }

  /// Refreshes the access token (T6.6).
  Future<AsyncValue<AuthSession>> refreshSession() async {
    try {
      return AsyncValue.data(await _authRepository.refreshSession());
    } catch (error, stackTrace) {
      return AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> signOut() => _authRepository.signOut();

  /// Ensures a local [Profile] row exists for [session]'s user.
  ///
  /// Creates one from the session when the user has no profile yet. The
  /// participant id is generated locally; the backend reconciliation happens
  /// in the sync layer (Phase 7/8).
  Future<void> _bootstrapProfile(AuthSession session) async {
    final existing =
        await _profileRepository.getProfileByUserId(session.userId);
    if (existing != null) return;
    await _profileRepository.createProfile(
      Profile(
        userId: session.userId,
        participantId: _uuid.v4(),
        displayName: session.phoneNumber ?? 'User',
        phoneNumber: session.phoneNumber ?? '',
        createdAt: DateTime.now(),
      ),
    );
  }
}
