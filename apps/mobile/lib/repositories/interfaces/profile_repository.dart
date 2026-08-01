import 'package:settl/models/profile.dart';

/// Contract for profile persistence.
///
/// Implementations back the UI with local storage (Drift DAOs) or, once the
/// sync layer lands, a remote API. The UI and services depend on this
/// interface only — never on HTTP or database details.
abstract class ProfileRepository {
  Future<Profile?> getProfileByUserId(String userId);

  Future<Profile?> getProfileByParticipantId(String participantId);

  Future<List<Profile>> getAllProfiles();

  Future<void> createProfile(Profile profile);

  Future<void> updateProfile(Profile profile);

  Future<void> deleteProfileByUserId(String userId);
}
