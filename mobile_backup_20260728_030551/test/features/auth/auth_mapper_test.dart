import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/dto/auth_token_dto.dart';
import 'package:mobile/features/auth/data/dto/user_dto.dart';
import 'package:mobile/features/auth/data/mappers/auth_mapper.dart';
import 'package:mobile/features/auth/domain/models/user_session.dart';

void main() {
  group('AuthMapper Unit Tests', () {
    test('fromDto correctly maps AuthTokenDto to UserSession without local JWT decoding', () {
      const dto = AuthTokenDto(
        accessToken: 'access-xyz',
        refreshToken: 'refresh-123',
        tokenType: 'bearer',
        expiresIn: 900,
        user: UserDto(
          id: 'usr-456',
          phoneNumber: '+254712345678',
          role: 'rider',
        ),
      );

      final session = AuthMapper.fromDto(dto);

      expect(session.userId, equals('usr-456'));
      expect(session.phoneNumber, equals('+254712345678'));
      expect(session.role, equals(UserRole.rider));
      expect(session.isExpired, isFalse);
    });

    test('Amendment 20: UserSession detects proactive refresh buffer (under 3 minutes remaining)', () {
      final sessionProactive = UserSession(
        userId: 'usr-1',
        phoneNumber: '+254712345678',
        role: UserRole.passenger,
        expiresAt: DateTime.now().toUtc().add(const Duration(seconds: 120)),
      );

      final sessionFresh = UserSession(
        userId: 'usr-1',
        phoneNumber: '+254712345678',
        role: UserRole.passenger,
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15)),
      );

      expect(sessionProactive.shouldProactivelyRefresh, isTrue);
      expect(sessionFresh.shouldProactivelyRefresh, isFalse);
    });
  });
}
