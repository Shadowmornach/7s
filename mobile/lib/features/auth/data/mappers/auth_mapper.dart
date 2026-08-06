import '../dto/auth_token_dto.dart';
import '../../domain/models/user_session.dart';

class AuthMapper {
  static UserSession fromDto(AuthTokenDto dto) {
    final nowUtc = DateTime.now().toUtc();
    final expiresAt = nowUtc.add(Duration(seconds: dto.expiresIn));

    return UserSession(
      uid: dto.user.id,
      email: dto.user.email.isNotEmpty ? dto.user.email : 'user@7s.delivery',
      nickname: dto.user.nickname ?? dto.user.email.split('@').first,
      phoneNumber: dto.user.phoneNumber,
      serviceZone: 'VOI',
      preferredPaymentMethod: 'Cash',
      role: UserSession.parseRole(dto.user.role),
      isProfileComplete: dto.user.isProfileComplete,
      isActive: true,
      createdAt: nowUtc,
      updatedAt: nowUtc,
      lastLogin: nowUtc,
      expiresAt: expiresAt,
    );
  }
}
