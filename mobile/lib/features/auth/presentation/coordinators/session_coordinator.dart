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
      _state = AuthState.unauthenticated;
    }
  }

  Future<UserSession> refreshTokenSingleFlight() async {
    if (_activeRefreshFuture != null) {
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

  Future<void> signInWithEmail(String email, String password) async {
    _state = AuthState.refreshing;
    try {
      final session = await _authRepository.signInWithEmail(
        email: email,
        password: password,
      );
      _currentSession = session;
      _state = AuthState.authenticated;
    } catch (e) {
      _currentSession = null;
      _state = AuthState.failed;
      rethrow;
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    _state = AuthState.refreshing;
    try {
      final session = await _authRepository.signUpWithEmail(
        email: email,
        password: password,
      );
      _currentSession = session;
      _state = AuthState.authenticated;
    } catch (e) {
      _currentSession = null;
      _state = AuthState.failed;
      rethrow;
    }
  }

  Future<void> completeProfile({
    required String nickname,
    String? fullName,
    String? photoUrl,
    String? themePreference,
    String? emergencyContact,
  }) async {
    try {
      final session = await _authRepository.completeProfile(
        nickname: nickname,
        fullName: fullName,
        photoUrl: photoUrl,
        themePreference: themePreference,
        emergencyContact: emergencyContact,
      );
      _currentSession = session;
      _state = AuthState.authenticated;
    } catch (e) {
      _state = AuthState.failed;
      rethrow;
    }
  }

  void updatePhoneNumber(String? phone) {
    if (_currentSession != null) {
      if (phone == null || phone.trim().isEmpty) {
        _currentSession = UserSession(
          uid: _currentSession!.uid,
          email: _currentSession!.email,
          nickname: _currentSession!.nickname,
          fullName: _currentSession!.fullName,
          photoUrl: _currentSession!.photoUrl,
          phoneNumber: null,
          serviceZone: _currentSession!.serviceZone,
          preferredPaymentMethod: _currentSession!.preferredPaymentMethod,
          favoritePlaces: _currentSession!.favoritePlaces,
          homeLocation: _currentSession!.homeLocation,
          workLocation: _currentSession!.workLocation,
          role: _currentSession!.role,
          isProfileComplete: _currentSession!.isProfileComplete,
          isActive: _currentSession!.isActive,
          createdAt: _currentSession!.createdAt,
          updatedAt: DateTime.now().toUtc(),
          lastLogin: _currentSession!.lastLogin,
          expiresAt: _currentSession!.expiresAt,
        );
      } else {
        _currentSession = _currentSession!.copyWith(phoneNumber: phone);
      }
    }
  }


  Future<void> sendPasswordResetEmail(String email) async {
    await _authRepository.sendPasswordResetEmail(email: email);
  }

  Future<bool> verifyPasswordResetOtp(String email, String otp) async {
    return await _authRepository.verifyPasswordResetOtp(
      email: email,
      otp: otp,
    );
  }

  Future<void> resetPasswordWithOtp(String email, String otp, String newPassword) async {
    await _authRepository.resetPasswordWithOtp(
      email: email,
      otp: otp,
      newPassword: newPassword,
    );
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
