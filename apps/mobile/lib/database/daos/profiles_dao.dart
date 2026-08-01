import 'package:drift/drift.dart';

import '../app_database.dart';
import '../../models/profile.dart';

part 'profiles_dao.g.dart';

/// CRUD access to [Profiles], mapped to the [Profile] domain model.
@DriftAccessor(tables: [Profiles])
class ProfilesDao extends DatabaseAccessor<AppDatabase>
    with _$ProfilesDaoMixin {
  ProfilesDao(super.db);

  Future<Profile?> getProfileByUserId(String userId) async {
    final row = await (select(profiles)
          ..where((tbl) => tbl.userId.equals(userId)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<Profile?> getProfileByParticipantId(String participantId) async {
    final row = await (select(profiles)
          ..where((tbl) => tbl.participantId.equals(participantId)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<List<Profile>> getAllProfiles() async {
    final rows = await select(profiles).get();
    return rows.map(_fromRow).toList();
  }

  Future<void> createProfile(Profile profile) async {
    await into(profiles).insert(ProfilesCompanion.insert(
      userId: profile.userId,
      participantId: profile.participantId,
      displayName: profile.displayName,
      phoneNumber: profile.phoneNumber,
      upiId: Value(profile.upiId),
      createdAt: profile.createdAt,
    ));
  }

  Future<void> updateProfile(Profile profile) async {
    await (update(profiles)..where((tbl) => tbl.userId.equals(profile.userId)))
        .write(ProfilesCompanion(
      participantId: Value(profile.participantId),
      displayName: Value(profile.displayName),
      phoneNumber: Value(profile.phoneNumber),
      upiId: Value(profile.upiId),
    ));
  }

  Future<void> deleteProfileByUserId(String userId) async {
    await (delete(profiles)..where((tbl) => tbl.userId.equals(userId))).go();
  }

  Profile _fromRow(ProfileRow row) => Profile(
        userId: row.userId,
        participantId: row.participantId,
        displayName: row.displayName,
        phoneNumber: row.phoneNumber,
        upiId: row.upiId,
        createdAt: row.createdAt,
      );
}
