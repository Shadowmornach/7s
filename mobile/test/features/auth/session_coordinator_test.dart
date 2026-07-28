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
      userId: 'usr-1',
      phoneNumber: '+254712345678',
      role: UserRole.passenger,
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15)),
    );
  }

  @override
  Future<UserSession?> restoreSession() async => restoreResult;

  @override
  Future<void> requestOtp({required String phoneNumber}) async {}

  @override
  Future<UserSession> verifyOtp({required String phoneNumber, required String otpCode}) async {
    return UserSession(
      userId: 'usr-1',
      phoneNumber: phoneNumber,
      role: UserRole.passenger,
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15)),
    );
  }

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
      // Underlying repository refreshToken must be called exactly 1 time!
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
