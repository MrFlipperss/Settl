import 'package:settl/api/models/api_requests.dart';
import 'package:settl/api/profile_api.dart';
import 'package:settl/database/daos/profiles_dao.dart';
import 'package:settl/models/profile.dart';
import 'package:settl/repositories/interfaces/profile_repository.dart';

/// Drift-backed [ProfileRepository] with a remote mirror seam.
///
/// Delegates local persistence to [ProfilesDao] and remote profile upserts to
/// [ProfileApi]; no schema or HTTP knowledge leaks into the UI layer.
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfilesDao _dao;
  final ProfileApi _api;

  ProfileRepositoryImpl(this._dao, this._api);

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

  @override
  Future<void> ensureRemoteProfile(Profile profile) async {
    await _api.createProfile(ApiCreateProfileRequest(
      displayName: profile.displayName,
      phoneNumber: profile.phoneNumber,
      upiId: profile.upiId,
    ));
  }
}
