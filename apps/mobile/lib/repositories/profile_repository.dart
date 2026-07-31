import 'package:drift/drift.dart';
import 'package:settl/database/database.dart';
import 'package:settl/models/profile.dart';

class ProfileRepository {
  final Database _db;

  ProfileRepository(this._db);

  // Helper to get the drift database instance
  dynamic get _driftDb {
    return (_db as dynamic).instance;
  }

  Future<Profile?> getProfileByUserId(String userId) async {
    final result = await (_driftDb.profiles)
        .where((tbl) => tbl.userId.equals(userId))
        .get()
        .first;

    return result.isNotEmpty ? Profile.fromJson(result.first.toJson()) : null;
  }

  Future<Profile?> getProfileByParticipantId(String participantId) async {
    final result = await (_driftDb.profiles)
        .where((tbl) => tbl.participantId.equals(participantId))
        .get()
        .first;

    return result.isNotEmpty ? Profile.fromJson(result.first.toJson()) : null;
  }

  Future<List<Profile>> getAllProfiles() async {
    final result = await _driftDb.select(_driftDb.profiles).get();
    return result.map((row) => Profile.fromJson(row.toJson())).toList();
  }

  Future<void> createProfile(Profile profile) async {
    await _driftDb.insert(_driftDb.profiles).insert(profile.toCompanion(true));
  }

  Future<void> updateProfile(Profile profile) async {
    await _driftDb.update(_driftDb.profiles).replace(profile.toCompanion(true));
  }

  Future<void> deleteProfileByUserId(String userId) async {
    await (_driftDb.profiles)
        .where((tbl) => tbl.userId.equals(userId))
        .delete();
  }
}