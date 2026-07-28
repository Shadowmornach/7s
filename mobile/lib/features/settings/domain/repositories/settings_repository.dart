import '../models/user_profile.dart';
import '../models/saved_place.dart';

abstract class SettingsRepository {
  Future<UserProfile> getUserProfile();

  Future<UserProfile> updateProfile({
    required String fullName,
    required String email,
  });

  Future<List<SavedPlace>> getSavedPlaces();

  Future<void> addSavedPlace(SavedPlace place);
}
