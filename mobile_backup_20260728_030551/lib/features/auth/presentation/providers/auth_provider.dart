import 'package:flutter/foundation.dart';
import '../coordinators/session_coordinator.dart';
import '../../domain/models/user_session.dart';

class AuthNotifier extends ChangeNotifier {
  final SessionCoordinator _sessionCoordinator;

  AuthNotifier({required SessionCoordinator sessionCoordinator})
      : _sessionCoordinator = sessionCoordinator;

  AuthState get state => _sessionCoordinator.state;
  UserSession? get currentSession => _sessionCoordinator.currentSession;

  Future<void> restoreSession() async {
    await _sessionCoordinator.restoreSession();
    notifyListeners();
  }

  Future<void> requestOtp(String phoneNumber) async {
    try {
      await _sessionCoordinator.requestOtp(phoneNumber);
    } finally {
      notifyListeners();
    }
  }

  Future<void> login(String phoneNumber, String otpCode) async {
    try {
      await _sessionCoordinator.login(phoneNumber, otpCode);
    } finally {
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _sessionCoordinator.logout();
    notifyListeners();
  }
}
