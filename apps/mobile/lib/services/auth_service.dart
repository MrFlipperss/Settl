import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/auth_session.dart';
import '../models/profile.dart';
import '../repositories/interfaces/auth_repository.dart';
import '../repositories/interfaces/profile_repository.dart';
import '../utils/phone_utils.dart';

/// Application-facing authentication facade.
///
/// Supports both phone OTP and email/password authentication flows.
/// Normalizes phone numbers to E.164, delegates to [AuthRepository], and
/// surfaces results as [AsyncValue]s ready for Riverpod widgets. Also
/// bootstraps a local [Profile] row for the signed-in user (T6.5).
class AuthService {
  AuthService({
    required AuthRepository authRepository,
    required ProfileRepository profileRepository,
  })  : _authRepository = authRepository,
        _profileRepository = profileRepository,
        _isLoading = false;

  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;
  bool _isLoading;
  static const _uuid = Uuid();

  bool get isAuthenticated => _authRepository.currentSession != null;

  AuthSession? get currentSession => _authRepository.currentSession;

  bool get isLoading => _isLoading;

  Stream<AuthSession?> get onAuthStateChanged =>
      _authRepository.onAuthStateChanged;

  /// Sets the loading state
  void _setLoading(bool isLoading) {
    _isLoading = isLoading;
  }

  /// Sends a one-time phone password to [rawPhone] after E.164 normalization.
  Future<AsyncValue<void>> signInWithPhone(String rawPhone) async {
    _setLoading(true);
    try {
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
    } finally {
      _setLoading(false);
    }
  }

  /// Verifies [token] received on [rawPhone] and returns the new session.
  ///
  /// On success, ensures a local [Profile] row exists for the user (T6.5).
  Future<AsyncValue<AuthSession>> verifyOtp({
    required String rawPhone,
    required String token,
  }) async {
    _setLoading(true);
    try {
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
    } finally {
      _setLoading(false);
    }
  }

  /// Restores a persisted session (e.g. on app start). Returns null when the
  /// user is signed out.
  Future<AsyncValue<AuthSession?>> restoreSession() async {
    _setLoading(true);
    try {
      try {
        return AsyncValue.data(await _authRepository.restoreSession());
      } catch (error, stackTrace) {
        return AsyncValue.error(error, stackTrace);
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Signs in with email and password.
  ///
  /// On success, ensures a local [Profile] row exists for the user (T6.5).
  Future<AsyncValue<AuthSession>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final trimmedEmail = email.trim();
      if (trimmedEmail.isEmpty) {
        return AsyncValue.error(
          ArgumentError('Email cannot be empty'),
          StackTrace.current,
        );
      }
      if (password.isEmpty) {
        return AsyncValue.error(
          ArgumentError('Password cannot be empty'),
          StackTrace.current,
        );
      }
      try {
        final session = await _authRepository.signInWithEmail(
          email: trimmedEmail,
          password: password,
        );
        final existing =
            await _profileRepository.getProfileByUserId(session.userId);

        final hasSessionPhone = session.phoneNumber?.trim().isNotEmpty ?? false;
        final hasExistingPhone =
            existing?.phoneNumber.trim().isNotEmpty ?? false;

        if (hasSessionPhone || hasExistingPhone) {
          await _bootstrapProfile(
            session,
            existingProfile: existing,
          );
        }
        return AsyncValue.data(session);
      } catch (error, stackTrace) {
        return AsyncValue.error(error, stackTrace);
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Signs up with email and password.
  ///
  /// On success, ensures a local [Profile] row exists for the user (T6.5).
  Future<AsyncValue<AuthSession>> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    required String phoneNumber,
  }) async {
    _setLoading(true);
    try {
      final trimmedEmail = email.trim();
      final trimmedName = displayName.trim();
      final normalizedPhone = normalizePhone(phoneNumber);

      if (trimmedEmail.isEmpty) {
        return AsyncValue.error(
          ArgumentError('Email cannot be empty'),
          StackTrace.current,
        );
      }

      if (password.length < 6) {
        return AsyncValue.error(
          ArgumentError('Password must be at least 6 characters'),
          StackTrace.current,
        );
      }

      if (trimmedName.isEmpty) {
        return AsyncValue.error(
          ArgumentError('Display name cannot be empty'),
          StackTrace.current,
        );
      }

      if (normalizedPhone == null) {
        return AsyncValue.error(
          ArgumentError('Please enter a valid phone number'),
          StackTrace.current,
        );
      }

      final session = await _authRepository.signUpWithEmail(
        email: trimmedEmail,
        password: password,
        data: {
          'display_name': trimmedName,
          'phone_number': normalizedPhone,
        },
      );

      await _bootstrapProfile(
        session,
        phoneNumber: normalizedPhone,
        displayName: trimmedName,
      );

      return AsyncValue.data(session);
    } catch (error, stackTrace) {
      return AsyncValue.error(error, stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  Future<AsyncValue<void>> completeProfile({
    required String phoneNumber,
  }) async {
    _setLoading(true);

    try {
      final session = currentSession;
      if (session == null) {
        throw StateError('Please sign in again to complete your profile.');
      }

      final normalizedPhone = normalizePhone(phoneNumber);
      if (normalizedPhone == null) {
        throw ArgumentError('Please enter a valid phone number.');
      }

      final existing =
          await _profileRepository.getProfileByUserId(session.userId);

      final profile = existing == null
          ? Profile(
              userId: session.userId,
              participantId: _uuid.v4(),
              displayName: session.email?.split('@').first ?? 'User',
              phoneNumber: normalizedPhone,
              createdAt: DateTime.now(),
            )
          : existing.copyWith(phoneNumber: normalizedPhone);

      if (existing == null) {
        await _profileRepository.createProfile(profile);
      } else {
        await _profileRepository.updateProfile(profile);
      }

      final remoteProfile =
          await _profileRepository.ensureRemoteProfile(profile);

      if (remoteProfile.participantId != profile.participantId) {
        await _profileRepository.updateProfile(remoteProfile);
      }
      return const AsyncValue.data(null);
    } catch (error, stackTrace) {
      return AsyncValue.error(error, stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  /// Sends a password reset email to [email].
  Future<AsyncValue<void>> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    try {
      final trimmedEmail = email.trim();
      if (trimmedEmail.isEmpty) {
        return AsyncValue.error(
          ArgumentError('Email cannot be empty'),
          StackTrace.current,
        );
      }
      try {
        await _authRepository.sendPasswordResetEmail(trimmedEmail);
        return const AsyncValue.data(null);
      } catch (error, stackTrace) {
        return AsyncValue.error(error, stackTrace);
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Refreshes the access token (T6.6).
  Future<AsyncValue<AuthSession>> refreshSession() async {
    _setLoading(true);
    try {
      try {
        return AsyncValue.data(await _authRepository.refreshSession());
      } catch (error, stackTrace) {
        return AsyncValue.error(error, stackTrace);
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() => _authRepository.signOut();

  /// Ensures a local [Profile] row exists for [session]'s user.
  ///
  /// Creates one from the session when the user has no profile yet. The
  /// participant id is generated locally; the backend reconciliation happens
  /// in the sync layer (Phase 7/8).
  Future<void> _bootstrapProfile(
    AuthSession session, {
    String? phoneNumber,
    String? displayName,
    Profile? existingProfile,
  }) async {
    final existing = existingProfile ??
        await _profileRepository.getProfileByUserId(session.userId);

    final resolvedPhone = [
      phoneNumber,
      session.phoneNumber,
      existing?.phoneNumber,
    ].whereType<String>().firstWhere(
          (phone) => phone.trim().isNotEmpty,
          orElse: () => '',
        );

    if (resolvedPhone.trim().isEmpty) {
      throw ArgumentError(
        'A phone number is required to complete your profile.',
      );
    }

    final profile = existing ??
        Profile(
          userId: session.userId,
          participantId: _uuid.v4(),
          displayName: displayName ?? session.email?.split('@').first ?? 'User',
          phoneNumber: resolvedPhone,
          createdAt: DateTime.now(),
        );

    if (existing == null) {
      await _profileRepository.createProfile(profile);
    }

    final remoteProfile = await _profileRepository.ensureRemoteProfile(profile);

    if (remoteProfile.participantId != profile.participantId) {
      await _profileRepository.updateProfile(remoteProfile);
    }
  }
}
