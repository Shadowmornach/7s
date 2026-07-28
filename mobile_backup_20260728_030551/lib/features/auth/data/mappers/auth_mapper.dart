import '../dto/auth_token_dto.dart';
import '../../domain/models/user_session.dart';

class AuthMapper {
  static UserSession fromDto(AuthTokenDto dto) {
    final nowUtc = DateTime.now().toUtc();
    final expiresAt = nowUtc.add(Duration(seconds: dto.expiresIn));

    return UserSession(
      userId: dto.user.id,
      phoneNumber: dto.user.phoneNumber,
      role: UserSession.parseRole(dto.user.role),
      expiresAt: expiresAt,
    );
  }
}
