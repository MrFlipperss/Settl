import '../database/database.dart';
import '../models/profile.dart';

class ProfileRepository {
  final Database _db;

  ProfileRepository(this._db);

  Future<Profile?> getProfile(String participantId) async {
    final response = await _db.client
        .from('profiles')
        .select()
        .eq('participant_id', participantId)
        .maybeSingle();
    if (response == null) return null;
    return Profile.fromJson(response);
  }

  Future<Profile> createProfile(Profile profile) async {
    final response = await _db.client
        .from('profiles')
        .insert(profile.toJson())
        .select()
        .single();
    return Profile.fromJson(response);
  }

  Future<Profile> updateProfile(Profile profile) async {
    final response = await _db.client
        .from('profiles')
        .update(profile.toJson())
        .eq('participant_id', profile.participantId)
        .select()
        .single();
    return Profile.fromJson(response);
  }
}
