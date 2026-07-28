import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/settings/domain/models/user_profile.dart';
import 'package:mobile/features/settings/domain/models/saved_place.dart';
import 'package:mobile/features/settings/domain/repositories/settings_repository.dart';
import 'package:mobile/features/settings/presentation/providers/settings_provider.dart';

class MockSettingsRepository implements SettingsRepository {
  @override
  Future<UserProfile> getUserProfile() async {
    return const UserProfile(
      userId: 'usr-1',
      fullName: 'Alex Kamau',
      email: 'alex@example.com',
      phoneNumber: '+254712345678',
      avatarUrl: '',
      isPhoneVerified: true,
      isEmailVerified: true,
    );
  }

  @override
  Future<UserProfile> updateProfile({required String fullName, required String email}) async {
    return UserProfile(
      userId: 'usr-1',
      fullName: fullName,
      email: email,
      phoneNumber: '+254712345678',
      avatarUrl: '',
      isPhoneVerified: true,
      isEmailVerified: true,
    );
  }

  @override
  Future<List<SavedPlace>> getSavedPlaces() async {
    return const [
      SavedPlace(placeId: 'sp-1', label: 'Home', address: 'Kilimani', latitude: -1.29, longitude: 36.78, icon: 'home'),
    ];
  }

  @override
  Future<void> addSavedPlace(SavedPlace place) async {}
}

void main() {
  group('SettingsNotifier Unit Tests', () {
    late MockSettingsRepository repo;

    setUp(() {
      repo = MockSettingsRepository();
    });

    test('loadSettings fetches profile and saved places', () async {
      final notifier = SettingsNotifier(repository: repo);

      expect(notifier.profile, isNull);
      expect(notifier.savedPlaces, isEmpty);

      await notifier.loadSettings();

      expect(notifier.profile, isNotNull);
      expect(notifier.profile!.fullName, equals('Alex Kamau'));
      expect(notifier.savedPlaces.length, equals(1));
    });
  });
}
