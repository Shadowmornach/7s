import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/connectivity/connectivity_service.dart';
import 'package:mobile/core/logging/app_logger.dart';
import 'package:mobile/features/auth/domain/models/user_session.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/presentation/coordinators/session_coordinator.dart';

class MockConnectivityService implements ConnectivityService {
  ConnectivityStatus status = ConnectivityStatus.online;
  final StreamController<ConnectivityStatus> _controller = StreamController.broadcast();

  @override
  Future<ConnectivityStatus> checkConnectivity() async => status;

  @override
  Stream<ConnectivityStatus> get onConnectivityChanged => _controller.stream;

  @override
  bool get isBackendReachable => status == ConnectivityStatus.online;
}

class MockAuthRepository implements AuthRepository {
  int refreshCallCount = 0;
  UserSession? restoreResult;
  bool throw401OnRefresh = false;

  @override
  Future<UserSession> refreshToken() async {
    refreshCallCount++;
    await Future.delayed(const Duration(milliseconds: 100));
    if (throw401OnRefresh) {
      throw Exception('401 Unauthorized');
    }
    return UserSession(
      uid: 'usr-1',
      email: 'test@example.com',
      nickname: 'Test',
      role: UserRole.customer,
      isProfileComplete: true,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      lastLogin: DateTime.now().toUtc(),
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15)),
    );
  }

  @override
  Future<UserSession?> restoreSession() async => restoreResult;

  @override
  Future<UserSession> signInWithEmail({required String email, required String password}) async {
    return UserSession(
      uid: 'usr-1',
      email: email,
      nickname: 'Test',
      role: UserRole.customer,
      isProfileComplete: true,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      lastLogin: DateTime.now().toUtc(),
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15)),
    );
  }

  @override
  Future<UserSession> signUpWithEmail({required String email, required String password}) async {
    return UserSession(
      uid: 'usr-1',
      email: email,
      nickname: '',
      role: UserRole.customer,
      isProfileComplete: false,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      lastLogin: DateTime.now().toUtc(),
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15)),
    );
  }

  @override
  Future<UserSession> signInWithGoogle({
    required String idToken,
    String? email,
    String? displayName,
    String? photoUrl,
  }) async {
    return UserSession(
      uid: 'usr-g-1',
      email: email ?? 'google@example.com',
      nickname: displayName ?? 'Google',
      role: UserRole.customer,
      isProfileComplete: false,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      lastLogin: DateTime.now().toUtc(),
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15)),
    );
  }

  @override
  Future<UserSession> completeProfile({required String nickname, String? fullName, String? photoUrl}) async {
    return UserSession(
      uid: 'usr-1',
      email: 'test@example.com',
      nickname: nickname,
      fullName: fullName,
      photoUrl: photoUrl,
      role: UserRole.customer,
      isProfileComplete: true,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      lastLogin: DateTime.now().toUtc(),
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15)),
    );
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<bool> isBiometricSupported() async => false;

  @override
  Future<UserSession?> authenticateWithBiometrics() async => null;
}

void main() {
  group('SessionCoordinator Unit Tests', () {
    late MockConnectivityService connectivityService;
    late MockAuthRepository authRepo;
    late AppLogger logger;

    setUp(() {
      connectivityService = MockConnectivityService();
      authRepo = MockAuthRepository();
      logger = AppLogger();
    });

    test('Single-Flight Refresh Lock ensures concurrent refresh requests join the same Future', () async {
      final coordinator = SessionCoordinator(
        authRepository: authRepo,
        connectivityService: connectivityService,
        logger: logger,
      );

      final f1 = coordinator.refreshTokenSingleFlight();
      final f2 = coordinator.refreshTokenSingleFlight();
      final f3 = coordinator.refreshTokenSingleFlight();

      final results = await Future.wait([f1, f2, f3]);

      expect(results.length, equals(3));
      expect(authRepo.refreshCallCount, equals(1));
    });

    test('App launch offline sets AuthState.offlineWaiting', () async {
      connectivityService.status = ConnectivityStatus.offline;
      final coordinator = SessionCoordinator(
        authRepository: authRepo,
        connectivityService: connectivityService,
        logger: logger,
      );

      await coordinator.restoreSession();

      expect(coordinator.state, equals(AuthState.offlineWaiting));
    });
  });
}
