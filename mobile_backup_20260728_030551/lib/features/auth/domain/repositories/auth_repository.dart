import '../models/user_session.dart';

abstract class AuthRepository {
  Future<void> requestOtp({
    required String phoneNumber,
  });

  Future<UserSession> verifyOtp({
    required String phoneNumber,
    required String otpCode,
  });

  Future<UserSession?> restoreSession();

  Future<UserSession> refreshToken();

  Future<void> logout();

  // Amendment 17: Biometric readiness interface hook (deferred to F4/F5)
  Future<bool> isBiometricSupported();
  Future<UserSession?> authenticateWithBiometrics();
}
