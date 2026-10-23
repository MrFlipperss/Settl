import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settl/models/auth_session.dart';
import 'package:settl/models/profile.dart';
import 'package:settl/repositories/interfaces/auth_repository.dart';
import 'package:settl/repositories/interfaces/profile_repository.dart';
import 'package:settl/services/auth_service.dart';
import 'package:settl/utils/phone_utils.dart';

void main() {
  group('normalizePhone', () {
    test('returns E.164 for a valid Indian number without country code', () {
      expect(normalizePhone('9876543210'), '+919876543210');
    });

    test('returns E.164 for a valid number with leading country code', () {
      expect(normalizePhone('+919876543210'), '+919876543210');
    });

    test('returns E.164 for a number with spaces and dashes', () {
      expect(normalizePhone('+91 98765 43210'), '+919876543210');
    });

    test('returns null for an empty or whitespace input', () {
      expect(normalizePhone(''), isNull);
      expect(normalizePhone('   '), isNull);
    });

    test('returns null for a clearly invalid number', () {
      expect(normalizePhone('123'), isNull);
      expect(normalizePhone('not-a-phone'), isNull);
    });
  });

  group('AuthSession', () {
    test('isExpired is false when expiresAt is null', () {
      const session = AuthSession(
        userId: 'u1',
        phoneNumber: '+919876543210',
        accessToken: 'token',
        refreshToken: 'refresh',
      );
      expect(session.isExpired, isFalse);
    });

    test('isExpired is false for a future expiry', () {
      final session = AuthSession(
        userId: 'u1',
        phoneNumber: '+919876543210',
        accessToken: 'token',
        refreshToken: 'refresh',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(session.isExpired, isFalse);
    });

    test('isExpired is true for a past expiry', () {
      final session = AuthSession(
        userId: 'u1',
        phoneNumber: '+919876543210',
        accessToken: 'token',
        refreshToken: 'refresh',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(session.isExpired, isTrue);
    });

    test('copyWith updates only provided fields', () {
      const session = AuthSession(
        userId: 'u1',
        phoneNumber: '+919876543210',
        accessToken: 'token',
        refreshToken: 'refresh',
      );
      final updated = session.copyWith(accessToken: 'new-token');
      expect(updated.userId, 'u1');
      expect(updated.accessToken, 'new-token');
      expect(updated.refreshToken, 'refresh');
    });

    test('equality compares all fields', () {
      const a = AuthSession(
        userId: 'u1',
        phoneNumber: '+919876543210',
        accessToken: 'token',
        refreshToken: 'refresh',
      );
      const b = AuthSession(
        userId: 'u1',
        phoneNumber: '+919876543210',
        accessToken: 'token',
        refreshToken: 'refresh',
      );
      expect(a, equals(b));
    });
  });

  group('AuthService', () {
    const phone = '+919876543210';
    const token = '123456';

    test('signInWithPhone normalizes the phone before sending the OTP', () async {
      final auth = FakeAuthRepository();
      final service = AuthService(
        authRepository: auth,
        profileRepository: FakeProfileRepository(),
      );

      final result = await service.signInWithPhone('9876543210');

      expect(result.hasError, isFalse);
      expect(auth.lastSentOtpPhone, phone);
    });

    test('signInWithPhone rejects an invalid phone', () async {
      final auth = FakeAuthRepository();
      final service = AuthService(
        authRepository: auth,
        profileRepository: FakeProfileRepository(),
      );

      final result = await service.signInWithPhone('not-a-phone');

      expect(result.hasError, isTrue);
      expect(auth.lastSentOtpPhone, isNull);
    });

    test('verifyOtp returns the session and bootstraps a profile', () async {
      final auth = FakeAuthRepository();
      final profiles = FakeProfileRepository();
      final service = AuthService(
        authRepository: auth,
        profileRepository: profiles,
      );

      final result = await service.verifyOtp(rawPhone: phone, token: token);

      expect(result.hasError, isFalse);
      expect(result.value?.userId, 'u1');
      expect(result.value?.accessToken, 'access-token');
      expect(auth.lastVerifiedPhone, phone);
      expect(auth.lastVerifiedToken, token);

      final profile = await profiles.getProfileByUserId('u1');
      expect(profile, isNotNull);
      expect(profile?.phoneNumber, phone);
    });

    test('verifyOtp does not duplicate an existing profile', () async {
      final auth = FakeAuthRepository();
      final profiles = FakeProfileRepository();
      final service = AuthService(
        authRepository: auth,
        profileRepository: profiles,
      );

      await profiles.createProfile(
        Profile(
          userId: 'u1',
          participantId: 'p-1',
          displayName: 'Existing',
          phoneNumber: phone,
          createdAt: DateTime.now(),
        ),
      );

      final result = await service.verifyOtp(rawPhone: phone, token: token);

      expect(result.hasError, isFalse);
      final all = await profiles.getAllProfiles();
      expect(all.length, 1);
      expect(all.single.displayName, 'Existing');
    });

    test('signUpWithEmail normalizes phone and bootstraps profile details',
        () async {
      final auth = FakeAuthRepository();
      final profiles = FakeProfileRepository();
      final service = AuthService(
        authRepository: auth,
        profileRepository: profiles,
      );

      final result = await service.signUpWithEmail(
        email: '  new@example.com ',
        password: 'password',
        displayName: '  New User ',
        phoneNumber: '9876543210',
      );

      expect(result.hasError, isFalse);
      expect(auth.lastSignUpEmail, 'new@example.com');
      expect(auth.lastSignUpData, {
        'display_name': 'New User',
        'phone_number': phone,
      });
      final profile = await profiles.getProfileByUserId('u1');
      expect(profile?.displayName, 'New User');
      expect(profile?.phoneNumber, phone);
    });

    test('signUpWithEmail rejects an invalid phone number', () async {
      final auth = FakeAuthRepository();
      final service = AuthService(
        authRepository: auth,
        profileRepository: FakeProfileRepository(),
      );

      final result = await service.signUpWithEmail(
        email: 'new@example.com',
        password: 'password',
        displayName: 'New User',
        phoneNumber: 'not-a-phone',
      );

      expect(result.hasError, isTrue);
      expect(auth.lastSignUpEmail, isNull);
    });

    test('restoreSession returns null when signed out', () async {
      final auth = FakeAuthRepository();
      final service = AuthService(
        authRepository: auth,
        profileRepository: FakeProfileRepository(),
      );

      final result = await service.restoreSession();

      expect(result.hasError, isFalse);
      expect(result.value, isNull);
      expect(service.isAuthenticated, isFalse);
    });

    test('restoreSession returns the persisted session when signed in',
        () async {
      final auth = FakeAuthRepository()..session = _testSession();
      final service = AuthService(
        authRepository: auth,
        profileRepository: FakeProfileRepository(),
      );

      final result = await service.restoreSession();

      expect(result.hasError, isFalse);
      expect(result.value?.userId, 'u1');
      expect(service.isAuthenticated, isTrue);
      expect(service.currentSession?.accessToken, 'access-token');
    });

    test('signOut delegates to the repository', () async {
      final auth = FakeAuthRepository()..session = _testSession();
      final service = AuthService(
        authRepository: auth,
        profileRepository: FakeProfileRepository(),
      );

      await service.signOut();

      expect(auth.session, isNull);
      expect(service.isAuthenticated, isFalse);
    });

    test('surfaces repository errors as AsyncValue errors', () async {
      final auth = FakeAuthRepository()
        ..failWith = Exception('network down');
      final service = AuthService(
        authRepository: auth,
        profileRepository: FakeProfileRepository(),
      );

      final result = await service.signInWithPhone('9876543210');

      expect(result.hasError, isTrue);
      expect(result.error, isA<Exception>());
    });
  });
}

AuthSession _testSession() => const AuthSession(
      userId: 'u1',
      phoneNumber: '+919876543210',
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );

/// In-memory [AuthRepository] fake for unit tests.
class FakeAuthRepository implements AuthRepository {
  AuthSession? session;
  Object? failWith;

  String? lastSentOtpPhone;
  String? lastVerifiedPhone;
  String? lastVerifiedToken;
  String? lastSignUpEmail;
  Map<String, dynamic>? lastSignUpData;

  final _controller = StreamController<AuthSession?>.broadcast();

  @override
  AuthSession? get currentSession => session;

  @override
  Stream<AuthSession?> get onAuthStateChanged => _controller.stream;

  void _maybeFail() {
    final error = failWith;
    if (error != null) throw error;
  }

  @override
  Future<void> sendOtp(String phone) async {
    _maybeFail();
    lastSentOtpPhone = phone;
  }

  @override
  Future<AuthSession> verifyOtp({
    required String phone,
    required String token,
  }) async {
    _maybeFail();
    lastVerifiedPhone = phone;
    lastVerifiedToken = token;
    session = _testSession();
    _controller.add(session);
    return session!;
  }

  @override
  Future<AuthSession?> restoreSession() async {
    _maybeFail();
    return session;
  }

  @override
  Future<AuthSession> refreshSession() async {
    _maybeFail();
    return session ?? _testSession();
  }

  @override
  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _maybeFail();
    session = _testSession();
    _controller.add(session);
    return session!;
  }

  @override
  Future<AuthSession> signUpWithEmail({
    required String email,
    required String password,
    required Map<String, dynamic> data,
  }) async {
    _maybeFail();
    lastSignUpEmail = email;
    lastSignUpData = data;
    session = AuthSession(
      userId: 'u1',
      email: email,
      phoneNumber: data['phone_number'] as String?,
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
    _controller.add(session);
    return session!;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    _maybeFail();
  }

  @override
  Future<void> signOut() async {
    _maybeFail();
    session = null;
    _controller.add(null);
  }
}

/// In-memory [ProfileRepository] fake for unit tests.
class FakeProfileRepository implements ProfileRepository {
  final List<Profile> _profiles = [];

  @override
  Future<Profile?> getProfileByUserId(String userId) async {
    for (final p in _profiles) {
      if (p.userId == userId) return p;
    }
    return null;
  }

  @override
  Future<Profile?> getProfileByParticipantId(String participantId) async {
    for (final p in _profiles) {
      if (p.participantId == participantId) return p;
    }
    return null;
  }

  @override
  Future<List<Profile>> getAllProfiles() async => List.unmodifiable(_profiles);

  @override
  Future<void> createProfile(Profile profile) async {
    _profiles.add(profile);
  }

  @override
  Future<void> updateProfile(Profile profile) async {
    final index = _profiles.indexWhere((p) => p.userId == profile.userId);
    if (index >= 0) _profiles[index] = profile;
  }

  @override
  Future<void> deleteProfileByUserId(String userId) async {
    _profiles.removeWhere((p) => p.userId == userId);
  }

  @override
  Future<Profile> ensureRemoteProfile(Profile profile) async {
    return profile;
  }
}
