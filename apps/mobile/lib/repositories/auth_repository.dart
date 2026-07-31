import 'package:settl/database/database.dart';
import 'package:settl/models/profile.dart';

class AuthRepository {
  final Database _db;

  AuthRepository(this._db);

  // For now, we'll keep Supabase for authentication since that's handled by Supabase Auth
  // But we'll store/retrieve user data from our local database
  Future<void> storeUserProfile(Profile profile) async {
    // Store user profile in local database
    await _db.into(_db.profiles).insert(profile.toCompanion(true));
  }

  Future<Profile?> getUserProfile(String userId) async {
    final result = await (self._db.profiles)
        .where((tbl) => tbl.userId.equals(userId))
        .get()
        .first;

    return result.isNotEmpty ? Profile.fromJson(result.first.toJson()) : null;
  }
}