import '../models/user_session.dart';

abstract class AuthRepository {
  Future<UserSession> signInWithEmail({
    required String email,
    required String password,
  });

  Future<UserSession> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<UserSession> signInWithGoogle({
    required String idToken,
    String? email,
    String? displayName,
    String? photoUrl,
  });

  Future<UserSession> completeProfile({
    required String nickname,
    String? fullName,
    String? photoUrl,
    String? themePreference,
    String? emergencyContact,
  });

  Future<void> sendPasswordResetEmail({
    required String email,
  });

  Future<bool> verifyPasswordResetOtp({
    required String email,
    required String otp,
  });

  Future<void> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  });

  Future<UserSession?> restoreSession();

  Future<UserSession> refreshToken();

  Future<void> logout();

  Future<bool> isBiometricSupported();
  Future<UserSession?> authenticateWithBiometrics();
}
