import 'package:flutter/foundation.dart';
import '../coordinators/session_coordinator.dart';
import '../../domain/models/user_session.dart';

class AuthNotifier extends ChangeNotifier {
  final SessionCoordinator _sessionCoordinator;

  AuthNotifier({required SessionCoordinator sessionCoordinator})
      : _sessionCoordinator = sessionCoordinator;

  AuthState get state => _sessionCoordinator.state;
  UserSession? get currentSession => _sessionCoordinator.currentSession;

  bool get isAuthenticated => state == AuthState.authenticated && currentSession != null;
  bool get isProfileComplete => currentSession?.isProfileComplete ?? false;

  Future<void> restoreSession() async {
    await _sessionCoordinator.restoreSession();
    notifyListeners();
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _sessionCoordinator.signInWithEmail(email, password);
    } finally {
      notifyListeners();
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    try {
      await _sessionCoordinator.signUpWithEmail(email, password);
    } finally {
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle({
    required String idToken,
    String? email,
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      await _sessionCoordinator.signInWithGoogle(
        idToken: idToken,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
      );
    } finally {
      notifyListeners();
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
      await _sessionCoordinator.completeProfile(
        nickname: nickname,
        fullName: fullName,
        photoUrl: photoUrl,
        themePreference: themePreference,
        emergencyContact: emergencyContact,
      );
    } finally {
      notifyListeners();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _sessionCoordinator.sendPasswordResetEmail(email);
  }

  Future<bool> verifyPasswordResetOtp(String email, String otp) async {
    return await _sessionCoordinator.verifyPasswordResetOtp(email, otp);
  }

  Future<void> resetPasswordWithOtp(String email, String otp, String newPassword) async {
    await _sessionCoordinator.resetPasswordWithOtp(email, otp, newPassword);
  }

  void updatePhoneNumber(String? phone) {
    _sessionCoordinator.updatePhoneNumber(phone);
    notifyListeners();
  }



  Future<void> logout() async {
    await _sessionCoordinator.logout();
    notifyListeners();
  }
}
