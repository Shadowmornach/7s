import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/settings/data/dto/user_profile_dto.dart';
import 'package:mobile/features/settings/data/dto/saved_place_dto.dart';
import 'package:mobile/features/settings/data/mappers/settings_mapper.dart';

void main() {
  group('SettingsMapper Unit Tests', () {
    test('profileFromDto maps UserProfileDto to UserProfile domain model', () {
      const dto = UserProfileDto(
        userId: 'usr-1',
        fullName: 'Alex Kamau',
        email: 'alex@example.com',
        phoneNumber: '+254712345678',
        avatarUrl: 'https://cdn.7s.co.ke/avatar.png',
        isPhoneVerified: true,
        isEmailVerified: true,
      );

      final profile = SettingsMapper.profileFromDto(dto);

      expect(profile.userId, equals('usr-1'));
      expect(profile.fullName, equals('Alex Kamau'));
      expect(profile.isPhoneVerified, isTrue);
    });

    test('placeFromDto maps SavedPlaceDto to SavedPlace domain model', () {
      const dto = SavedPlaceDto(
        placeId: 'sp-1',
        label: 'Home',
        address: 'Kilimani, Nairobi',
        latitude: -1.2921,
        longitude: 36.7821,
        icon: 'home',
      );

      final place = SettingsMapper.placeFromDto(dto);

      expect(place.placeId, equals('sp-1'));
      expect(place.label, equals('Home'));
    });
  });
}
