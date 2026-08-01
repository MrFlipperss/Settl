import 'package:settl/database/daos/profiles_dao.dart';
import 'package:settl/models/profile.dart';
import 'package:settl/repositories/interfaces/profile_repository.dart';

/// Drift-backed [ProfileRepository].
///
/// Delegates all persistence to [ProfilesDao]; no HTTP or schema knowledge
/// leaks into the UI layer.
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfilesDao _dao;

  ProfileRepositoryImpl(this._dao);

  @override
  Future<Profile?> getProfileByUserId(String userId) =>
      _dao.getProfileByUserId(userId);

  @override
  Future<Profile?> getProfileByParticipantId(String participantId) =>
      _dao.getProfileByParticipantId(participantId);

  @override
  Future<List<Profile>> getAllProfiles() => _dao.getAllProfiles();

  @override
  Future<void> createProfile(Profile profile) => _dao.createProfile(profile);

  @override
  Future<void> updateProfile(Profile profile) => _dao.updateProfile(profile);

  @override
  Future<void> deleteProfileByUserId(String userId) =>
      _dao.deleteProfileByUserId(userId);
}
