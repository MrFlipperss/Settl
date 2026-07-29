import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import '../repositories/profile_repository.dart';
import '../models/profile.dart';

class AuthService {
  final AuthRepository _authRepo;
  final ProfileRepository _profileRepo;

  AuthService(this._authRepo, this._profileRepo);

  bool get isAuthenticated => _authRepo.isAuthenticated;

  String? get userId => _authRepo.currentUser?.id;

  Future<AsyncValue<void>> signInWithPhone(String phone) async {
    try {
      await _authRepo.signInWithOtp(phone);
      return const AsyncValue.data(null);
    } catch (e) {
      return AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<AsyncValue<Profile?>> verifyOtp({
    required String phone,
    required String token,
  }) async {
    try {
      await _authRepo.verifyOtp(phone: phone, token: token);
      final uid = _authRepo.currentUser?.id;
      if (uid == null) throw Exception('No user after OTP verification');
      final profile = await _profileRepo.getProfile(uid);
      return AsyncValue.data(profile);
    } catch (e) {
      return AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> signOut() => _authRepo.signOut();
}
