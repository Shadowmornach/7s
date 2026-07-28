import 'dart:async';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/logging/app_logger.dart';
import '../dto/auth_token_dto.dart';
import '../mappers/auth_mapper.dart';
import '../../domain/models/user_session.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;
  final AppLogger _logger;

  AuthRepositoryImpl({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
    required AppLogger logger,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage,
        _logger = logger;

  @override
  Future<void> requestOtp({
    required String phoneNumber,
  }) async {
    _logger.info('Telemetry: [otp_request_started] for phone $phoneNumber');
    try {
      await _apiClient.post(
        ApiEndpoints.authOtpRequest,
        body: {'phone_number': phoneNumber},
        requiresAuth: false,
      );
    } catch (e, st) {
      _logger.error('Telemetry: [otp_request_failed]', e, st);
      rethrow;
    }
  }

  @override
  Future<UserSession> verifyOtp({
    required String phoneNumber,
    required String otpCode,
  }) async {
    _logger.info('Telemetry: [otp_verify_started]');
    try {
      final jsonResponse = await _apiClient.post(
        ApiEndpoints.authLogin,
        body: {'phone_number': phoneNumber, 'otp': otpCode},
        requiresAuth: false,
      );

      final tokenDto = AuthTokenDto.fromJson(jsonResponse as Map<String, dynamic>);
      await _tokenStorage.writeTokens(AuthTokens(
        accessToken: tokenDto.accessToken,
        refreshToken: tokenDto.refreshToken,
      ));

      final session = AuthMapper.fromDto(tokenDto);
      _logger.info('Telemetry: [otp_verify_success] User ID: ${session.userId}');
      return session;
    } catch (e, st) {
      _logger.error('Telemetry: [otp_verify_failed]', e, st);
      rethrow;
    }
  }

  @override
  Future<UserSession?> restoreSession() async {
    _logger.info('Telemetry: [session_restore_started]');
    final accessToken = await _tokenStorage.readAccessToken();
    final refreshTokenVal = await _tokenStorage.readRefreshToken();

    if (accessToken == null || refreshTokenVal == null) {
      _logger.info('Telemetry: [session_restore_none] No stored tokens found.');
      return null;
    }

    try {
      // Validate or refresh session against backend
      final session = await refreshToken();
      _logger.info('Telemetry: [session_restored] User ID: ${session.userId}, Role: ${session.role.name}');
      return session;
    } on UnauthorizedException {
      _logger.warning('Telemetry: [session_restore_expired] Stored refresh token rejected by backend.');
      await _tokenStorage.clearTokens();
      return null;
    } on NetworkException {
      // Defer session validation if network is offline
      _logger.warning('Telemetry: [session_restore_offline] Network offline during restore; deferring.');
      rethrow;
    } catch (e, st) {
      _logger.error('Telemetry: [session_restore_failed]', e, st);
      await _tokenStorage.clearTokens();
      return null;
    }
  }

  @override
  Future<UserSession> refreshToken() async {
    _logger.info('Telemetry: [token_refresh_started]');
    final storedRefreshToken = await _tokenStorage.readRefreshToken();
    if (storedRefreshToken == null || storedRefreshToken.isEmpty) {
      _logger.warning('Telemetry: [token_refresh_failed] No refresh token available');
      throw const UnauthorizedException('No refresh token available');
    }

    try {
      final jsonResponse = await _apiClient.post(
        ApiEndpoints.refreshToken,
        body: {'refresh_token': storedRefreshToken},
        requiresAuth: false,
      );

      final tokenDto = AuthTokenDto.fromJson(jsonResponse as Map<String, dynamic>);
      await _tokenStorage.writeTokens(AuthTokens(
        accessToken: tokenDto.accessToken,
        refreshToken: tokenDto.refreshToken,
      ));

      final session = AuthMapper.fromDto(tokenDto);
      _logger.info('Telemetry: [token_refreshed] Expiration updated to ${session.expiresAt}');
      return session;
    } on UnauthorizedException {
      // Refresh Loop Safeguard: 401 on refresh clears storage immediately and halts retries
      _logger.error('Telemetry: [refresh_failed_401] Refresh token rejected by server. Clearing storage.');
      await _tokenStorage.clearTokens();
      rethrow;
    } catch (e, st) {
      _logger.error('Telemetry: [token_refresh_error]', e, st);
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    _logger.info('Telemetry: [logout_started]');
    await _tokenStorage.clearTokens();
    _logger.info('Telemetry: [logout_complete]');
  }

  @override
  Future<bool> isBiometricSupported() async {
    // Amendment 17: Biometric readiness hook (deferred to F4/F5)
    return false;
  }

  @override
  Future<UserSession?> authenticateWithBiometrics() async {
    // Amendment 17: Biometric readiness hook (deferred to F4/F5)
    return null;
  }
}
