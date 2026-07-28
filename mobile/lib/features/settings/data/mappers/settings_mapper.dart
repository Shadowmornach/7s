import '../dto/user_profile_dto.dart';
import '../dto/saved_place_dto.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/saved_place.dart';

class SettingsMapper {
  static UserProfile profileFromDto(UserProfileDto dto) {
    return UserProfile(
      userId: dto.userId,
      fullName: dto.fullName,
      email: dto.email,
      phoneNumber: dto.phoneNumber,
      avatarUrl: dto.avatarUrl,
      isPhoneVerified: dto.isPhoneVerified,
      isEmailVerified: dto.isEmailVerified,
    );
  }

  static SavedPlace placeFromDto(SavedPlaceDto dto) {
    return SavedPlace(
      placeId: dto.placeId,
      label: dto.label,
      address: dto.address,
      latitude: dto.latitude,
      longitude: dto.longitude,
      icon: dto.icon,
    );
  }
}
