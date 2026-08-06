import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/dto/auth_token_dto.dart';
import 'package:mobile/features/auth/data/dto/user_dto.dart';
import 'package:mobile/features/auth/data/mappers/auth_mapper.dart';
import 'package:mobile/features/auth/domain/models/user_session.dart';

void main() {
  group('AuthMapper Unit Tests', () {
    test('fromDto correctly maps AuthTokenDto to UserSession', () {
      const dto = AuthTokenDto(
        accessToken: 'access-xyz',
        refreshToken: 'refresh-123',
        tokenType: 'bearer',
        expiresIn: 900,
        user: UserDto(
          id: 'usr-456',
          email: 'shadow@example.com',
          phoneNumber: '+254712345678',
          role: 'customer',
        ),
      );

      final session = AuthMapper.fromDto(dto);

      expect(session.uid, equals('usr-456'));
      expect(session.role, equals(UserRole.customer));
      expect(session.isExpired, isFalse);
    });

    test('UserSession detects proactive refresh buffer (under 3 minutes remaining)', () {
      final sessionProactive = UserSession(
        uid: 'usr-1',
        email: 'test@example.com',
        nickname: 'Test',
        role: UserRole.customer,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        lastLogin: DateTime.now().toUtc(),
        expiresAt: DateTime.now().toUtc().add(const Duration(seconds: 120)),
      );

      final sessionFresh = UserSession(
        uid: 'usr-1',
        email: 'test@example.com',
        nickname: 'Test',
        role: UserRole.customer,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        lastLogin: DateTime.now().toUtc(),
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15)),
      );

      expect(sessionProactive.shouldProactivelyRefresh, isTrue);
      expect(sessionFresh.shouldProactivelyRefresh, isFalse);
    });
  });
}
