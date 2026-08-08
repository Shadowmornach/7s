import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/models/user_session.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;
  final AppLogger _logger;

  UserSession? _cachedSession;

  AuthRepositoryImpl({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
    required AppLogger logger,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage,
        _logger = logger;

  /// Parses backend Token response into a UserSession and stores JWTs.
  /// Every auth method MUST go through this — no other path stores tokens.
  Future<UserSession> _processAuthResponse(Map<String, dynamic> response, String email) async {
    final token = response['access_token']?.toString();
    final refresh = response['refresh_token']?.toString();

    if (token == null || token.isEmpty || refresh == null || refresh.isEmpty) {
      throw const UnauthorizedException('Server returned invalid tokens');
    }

    await _tokenStorage.writeTokens(AuthTokens(accessToken: token, refreshToken: refresh));

    final session = UserSession(
      uid: response['uid']?.toString() ?? '',
      email: email,
      nickname: response['nickname']?.toString() ?? email.split('@')[0],
      fullName: response['full_name']?.toString(),
      photoUrl: response['photo_url']?.toString(),
      serviceZone: response['service_zone']?.toString() ?? 'VOI',
      preferredPaymentMethod: 'Cash',
      favoritePlaces: const [],
      role: UserSession.parseRole(response['role']?.toString() ?? 'customer'),
      isProfileComplete: response['is_profile_complete'] as bool? ?? false,
      isActive: true,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      lastLogin: DateTime.now().toUtc(),
      expiresAt: DateTime.now().toUtc().add(const Duration(days: 30)),
    );

    _cachedSession = session;
    return session;
  }

  @override
  Future<UserSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _logger.info('Auth: [email_signin_started] Email: $email');

    try {
      final supabase = Supabase.instance.client;
      final authResponse = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final session = authResponse.session;
      final user = authResponse.user;

      if (session != null && user != null) {
        await _tokenStorage.writeTokens(
          AuthTokens(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken ?? '',
          ),
        );
        final userSession = UserSession(
          uid: user.id,
          email: user.email ?? email,
          nickname: email.split('@')[0],
          serviceZone: 'VOI',
          preferredPaymentMethod: 'Cash',
          favoritePlaces: const [],
          role: UserSession.parseRole(user.userMetadata?['role']?.toString() ?? 'customer'),
          isProfileComplete: false,
          isActive: true,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
          lastLogin: DateTime.now().toUtc(),
          expiresAt: DateTime.now().toUtc().add(const Duration(days: 30)),
        );
        _cachedSession = userSession;
        _logger.info('Auth: [supabase_signin_success] UID: ${user.id}');
        return userSession;
      }
    } catch (e) {
      _logger.warning('Auth: [supabase_signin_failed] $e. Falling back to legacy endpoint.');
    }

    final response = await _apiClient.post(
      ApiEndpoints.authLogin,
      body: {'email': email, 'password': password},
      requiresAuth: false,
    );

    final session = await _processAuthResponse(response as Map<String, dynamic>, email);
    _logger.info('Auth: [email_signin_success] UID: ${session.uid}');
    return session;
  }

  @override
  Future<UserSession> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    _logger.info('Auth: [email_signup_started] Email: $email');

    try {
      final supabase = Supabase.instance.client;
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      final session = authResponse.session;
      final user = authResponse.user;

      if (session != null && user != null) {
        await _tokenStorage.writeTokens(
          AuthTokens(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken ?? '',
          ),
        );
        final userSession = UserSession(
          uid: user.id,
          email: user.email ?? email,
          nickname: email.split('@')[0],
          serviceZone: 'VOI',
          preferredPaymentMethod: 'Cash',
          favoritePlaces: const [],
          role: UserRole.customer,
          isProfileComplete: false,
          isActive: true,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
          lastLogin: DateTime.now().toUtc(),
          expiresAt: DateTime.now().toUtc().add(const Duration(days: 30)),
        );
        _cachedSession = userSession;
        _logger.info('Auth: [supabase_signup_success] UID: ${user.id}');
        return userSession;
      }
    } catch (e) {
      _logger.warning('Auth: [supabase_signup_failed] $e. Falling back to legacy endpoint.');
    }

    final response = await _apiClient.post(
      ApiEndpoints.authRegister,
      body: {'email': email, 'password': password},
      requiresAuth: false,
    );

    final session = await _processAuthResponse(response as Map<String, dynamic>, email);
    _logger.info('Auth: [email_signup_success] UID: ${session.uid}');
    return session;
  }

  @override
  Future<UserSession> completeProfile({
    required String nickname,
    String? fullName,
    String? photoUrl,
    String? themePreference,
    String? emergencyContact,
  }) async {
    _logger.info('Auth: [complete_profile] User: ${_cachedSession?.email}');
    final response = await _apiClient.post(
      ApiEndpoints.authProfileComplete,
      body: {
        'nickname': nickname,
        if (fullName != null) 'full_name': fullName,
        if (photoUrl != null) 'photo_url': photoUrl,
        if (themePreference != null) 'theme_preference': themePreference,
        if (emergencyContact != null) 'emergency_contact': emergencyContact,
      },
      requiresAuth: true,
    );

    // Update cached session with profile completion data
    if (_cachedSession != null) {
      final updated = UserSession(
        uid: _cachedSession!.uid,
        email: _cachedSession!.email,
        nickname: nickname.trim().isEmpty ? _cachedSession!.email.split('@')[0] : nickname.trim(),
        fullName: fullName ?? _cachedSession!.fullName,
        photoUrl: photoUrl ?? _cachedSession!.photoUrl,
        serviceZone: _cachedSession!.serviceZone,
        preferredPaymentMethod: _cachedSession!.preferredPaymentMethod,
        favoritePlaces: _cachedSession!.favoritePlaces,
        role: _cachedSession!.role,
        isProfileComplete: true,
        isActive: true,
        createdAt: _cachedSession!.createdAt,
        updatedAt: DateTime.now().toUtc(),
        lastLogin: _cachedSession!.lastLogin,
        expiresAt: _cachedSession!.expiresAt,
      );
      _cachedSession = updated;
      return updated;
    }

    throw const UnauthorizedException('No active session for profile completion');
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    _logger.info('Auth: [password_reset_request] Email: $email');
    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.resetPasswordForEmail(email);
      _logger.info('Auth: [supabase_password_reset_sent] Email: $email');
      return;
    } catch (e) {
      _logger.warning('Auth: [supabase_password_reset_failed] $e. Falling back to legacy endpoint.');
    }

    await _apiClient.post(
      ApiEndpoints.authForgotPasswordRequest,
      body: {'email': email},
      requiresAuth: false,
    );
  }

  @override
  Future<bool> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    _logger.info('Auth: [verify_otp_request] Email: $email');
    final response = await _apiClient.post(
      ApiEndpoints.authForgotPasswordVerifyOtp,
      body: {'email': email, 'otp': otp},
      requiresAuth: false,
    );
    return response['message'] == 'OTP verified successfully';
  }

  @override
  Future<void> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    _logger.info('Auth: [reset_password_request] Email: $email');
    await _apiClient.post(
      ApiEndpoints.authForgotPasswordReset,
      body: {'email': email, 'otp': otp, 'new_password': newPassword},
      requiresAuth: false,
    );
  }

  @override
  Future<UserSession?> restoreSession() async {
    _logger.info('Auth: [session_restore_started]');
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      _logger.info('Auth: [session_restore_none] No stored tokens found.');
      return null;
    }

    if (_cachedSession != null) {
      return _cachedSession;
    }

    // Validate the stored token against the backend.
    // If the token is expired/invalid, clear storage and force re-login.
    try {
      final refreshTokenStr = await _tokenStorage.readRefreshToken();
      if (refreshTokenStr == null || refreshTokenStr.isEmpty) {
        _logger.info('Auth: [session_restore_no_refresh] No refresh token. Clearing.');
        await _tokenStorage.clearTokens();
        return null;
      }

      final response = await _apiClient.post(
        ApiEndpoints.refreshToken,
        body: {'refresh_token': refreshTokenStr},
        requiresAuth: false,
      );

      final newAccess = (response as Map<String, dynamic>)['access_token']?.toString();
      final newRefresh = response['refresh_token']?.toString();

      if (newAccess == null || newAccess.isEmpty || newRefresh == null || newRefresh.isEmpty) {
        _logger.warning('Auth: [session_restore_invalid_response] Backend returned empty tokens.');
        await _tokenStorage.clearTokens();
        return null;
      }

      await _tokenStorage.writeTokens(AuthTokens(accessToken: newAccess, refreshToken: newRefresh));

      // Build session from the refresh response or decode JWT claims
      final session = UserSession(
        uid: response['uid']?.toString() ?? '',
        email: response['email']?.toString() ?? '',
        nickname: response['nickname']?.toString() ?? '',
        serviceZone: response['service_zone']?.toString() ?? 'VOI',
        preferredPaymentMethod: 'Cash',
        role: UserSession.parseRole(response['role']?.toString() ?? 'customer'),
        isProfileComplete: response['is_profile_complete'] as bool? ?? false,
        isActive: true,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        lastLogin: DateTime.now().toUtc(),
        expiresAt: DateTime.now().toUtc().add(const Duration(days: 30)),
      );

      _cachedSession = session;
      _logger.info('Auth: [session_restore_success] UID: ${session.uid}');
      return session;
    } catch (e) {
      _logger.warning('Auth: [session_restore_failed] Token refresh failed: $e. Clearing tokens.');
      await _tokenStorage.clearTokens();
      _cachedSession = null;
      return null;
    }
  }

  @override
  Future<UserSession> refreshToken() async {
    final current = await restoreSession();
    if (current != null) return current;
    throw const UnauthorizedException('No session available');
  }

  @override
  Future<void> logout() async {
    _logger.info('Auth: [logout_started]');
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    _cachedSession = null;
    await _tokenStorage.clearTokens();
    _logger.info('Auth: [logout_complete]');
  }

  @override
  Future<bool> isBiometricSupported() async => false;

  @override
  Future<UserSession?> authenticateWithBiometrics() async => null;
}
