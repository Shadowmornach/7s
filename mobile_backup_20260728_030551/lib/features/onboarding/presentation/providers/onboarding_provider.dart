import 'package:flutter/foundation.dart';
import '../../data/storage/onboarding_storage.dart';

class OnboardingProvider extends ChangeNotifier {
  static const int currentOnboardingVersion = 1;
  final OnboardingStorage _storage;

  int _currentPageIndex = 0;
  bool _isCompleted = false;

  OnboardingProvider({required OnboardingStorage storage}) : _storage = storage;

  int get currentPageIndex => _currentPageIndex;
  bool get isCompleted => _isCompleted;

  Future<void> checkOnboardingStatus() async {
    final version = await _storage.getOnboardingVersion();
    _isCompleted = version >= currentOnboardingVersion;
    notifyListeners();
  }

  void setPageIndex(int index) {
    _currentPageIndex = index;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    await _storage.setOnboardingVersion(currentOnboardingVersion);
    _isCompleted = true;
    notifyListeners();
  }

  Future<void> replayAppTour() async {
    _currentPageIndex = 0;
    _isCompleted = false;
    notifyListeners();
  }
}
