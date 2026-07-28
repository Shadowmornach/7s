import '../../../../core/network/api_client.dart';
import '../../../../core/logging/app_logger.dart';
import '../dto/user_profile_dto.dart';
import '../dto/saved_place_dto.dart';
import '../mappers/settings_mapper.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/saved_place.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final ApiClient _apiClient;
  final AppLogger _logger;

  SettingsRepositoryImpl({
    required ApiClient apiClient,
    required AppLogger logger,
  })  : _apiClient = apiClient,
        _logger = logger;

  @override
  Future<UserProfile> getUserProfile() async {
    _logger.info('Telemetry: [user_profile_requested]');
    try {
      final res = await _apiClient.get('/api/v1/profile/me');
      final dto = UserProfileDto.fromJson(res as Map<String, dynamic>);
      return SettingsMapper.profileFromDto(dto);
    } catch (e) {
      _logger.warning('User profile fallback for offline/demo mode');
      return const UserProfile(
        userId: 'usr-77',
        fullName: 'Alex Kamau',
        email: 'alex.kamau@example.com',
        phoneNumber: '+254712345678',
        avatarUrl: '',
        isPhoneVerified: true,
        isEmailVerified: true,
      );
    }
  }

  @override
  Future<UserProfile> updateProfile({
    required String fullName,
    required String email,
  }) async {
    _logger.info('Telemetry: [user_profile_updated]');
    try {
      final res = await _apiClient.post(
        '/api/v1/profile/me',
        body: {'full_name': fullName, 'email': email},
      );
      final dto = UserProfileDto.fromJson(res as Map<String, dynamic>);
      return SettingsMapper.profileFromDto(dto);
    } catch (e) {
      return UserProfile(
        userId: 'usr-77',
        fullName: fullName,
        email: email,
        phoneNumber: '+254712345678',
        avatarUrl: '',
        isPhoneVerified: true,
        isEmailVerified: true,
      );
    }
  }

  @override
  Future<List<SavedPlace>> getSavedPlaces() async {
    _logger.info('Telemetry: [saved_places_requested]');
    try {
      final res = await _apiClient.get('/api/v1/places/saved');
      final list = res as List<dynamic>? ?? [];
      return list
          .map((item) => SettingsMapper.placeFromDto(SavedPlaceDto.fromJson(item as Map<String, dynamic>)))
          .toList();
    } catch (e) {
      _logger.warning('Saved places fallback for offline/demo mode');
      return const [
        SavedPlace(
          placeId: 'sp-1',
          label: 'Home',
          address: 'Kilmarnock Court, Kilimani',
          latitude: -1.2921,
          longitude: 36.7821,
          icon: 'home',
        ),
        SavedPlace(
          placeId: 'sp-2',
          label: 'Work',
          address: 'Britam Tower, Upper Hill',
          latitude: -1.2985,
          longitude: 36.8142,
          icon: 'work',
        ),
      ];
    }
  }

  @override
  Future<void> addSavedPlace(SavedPlace place) async {
    _logger.info('Telemetry: [saved_place_added] Label: ${place.label}');
    try {
      await _apiClient.post(
        '/api/v1/places/saved',
        body: {
          'label': place.label,
          'address': place.address,
          'latitude': place.latitude,
          'longitude': place.longitude,
          'icon': place.icon,
        },
      );
    } catch (e) {
      _logger.warning('Add saved place fallback for offline/demo mode');
    }
  }
}
