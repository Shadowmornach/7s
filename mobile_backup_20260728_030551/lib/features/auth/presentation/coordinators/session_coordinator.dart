import 'dart:async';
import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/models/user_session.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthState {
  restoring,
  authenticated,
  unauthenticated,
  refreshing,
  offlineWaiting,
  expired,
  failed,
}

class SessionCoordinator {
  final AuthRepository _authRepository;
  final ConnectivityService _connectivityService;
  final AppLogger _logger;

  AuthState _state = AuthState.restoring;
  UserSession? _currentSession;
  Future<UserSession>? _activeRefreshFuture;
  StreamSubscription<ConnectivityStatus>? _connectivitySub;

  SessionCoordinator({
    required AuthRepository authRepository,
    required ConnectivityService connectivityService,
    required AppLogger logger,
  })  : _authRepository = authRepository,
        _connectivityService = connectivityService,
        _logger = logger {
    _initConnectivityListener();
  }

  AuthState get state => _state;
  UserSession? get currentSession => _currentSession;

  void _initConnectivityListener() {
    _connectivitySub = _connectivityService.onConnectivityChanged.listen((status) {
      if (_state == AuthState.offlineWaiting && status == ConnectivityStatus.online) {
        _logger.info('Telemetry: [connectivity_restored] Resuming session validation...');
        restoreSession();
      }
    });
  }

  Future<void> restoreSession() async {
    _state = AuthState.restoring;

    final connectivity = await _connectivityService.checkConnectivity();
    if (connectivity != ConnectivityStatus.online) {
      _logger.warning('Telemetry: [offline_waiting] App launch offline. Deferring backend validation.');
      _state = AuthState.offlineWaiting;
      return;
    }

    try {
      final session = await _authRepository.restoreSession();
      if (session != null) {
        _currentSession = session;
        _state = AuthState.authenticated;
      } else {
        _currentSession = null;
        _state = AuthState.unauthenticated;
      }
    } catch (e, st) {
      _logger.error('Session restoration exception', e, st);
      _currentSession = null;
      _state = AuthState.failed;
    }
  }

  /// Single-Flight Refresh Locking:
  /// Concurrent callers await the exact same refresh Future rather than firing duplicate network requests.
  Future<UserSession> refreshTokenSingleFlight() async {
    if (_activeRefreshFuture != null) {
      _logger.info('Telemetry: [single_flight_refresh_await] Joined active in-flight refresh request.');
      return _activeRefreshFuture!;
    }

    _state = AuthState.refreshing;
    _activeRefreshFuture = _authRepository.refreshToken();

    try {
      final newSession = await _activeRefreshFuture!;
      _currentSession = newSession;
      _state = AuthState.authenticated;
      return newSession;
    } catch (e) {
      _currentSession = null;
      _state = AuthState.expired;
      rethrow;
    } finally {
      _activeRefreshFuture = null;
    }
  }

  Future<void> requestOtp(String phoneNumber) async {
    try {
      await _authRepository.requestOtp(phoneNumber: phoneNumber);
    } catch (e) {
      _state = AuthState.failed;
      rethrow;
    }
  }

  Future<void> login(String phoneNumber, String otpCode) async {
    _state = AuthState.refreshing;
    try {
      final session = await _authRepository.verifyOtp(
        phoneNumber: phoneNumber,
        otpCode: otpCode,
      );
      _currentSession = session;
      _state = AuthState.authenticated;
    } catch (e) {
      _currentSession = null;
      _state = AuthState.failed;
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _currentSession = null;
    _state = AuthState.unauthenticated;
  }

  void dispose() {
    _connectivitySub?.cancel();
  }
}
