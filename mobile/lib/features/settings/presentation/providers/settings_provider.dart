import 'package:flutter/material.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/saved_place.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsNotifier extends ChangeNotifier {
  final SettingsRepository _repository;

  UserProfile? _profile;
  List<SavedPlace> _savedPlaces = [];
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = false;

  SettingsNotifier({required SettingsRepository repository}) : _repository = repository;

  UserProfile? get profile => _profile;
  List<SavedPlace> get savedPlaces => _savedPlaces;
  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      _profile = await _repository.getUserProfile();
      _savedPlaces = await _repository.getSavedPlaces();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({required String fullName, required String email}) async {
    _profile = await _repository.updateProfile(fullName: fullName, email: email);
    notifyListeners();
  }

  Future<void> addSavedPlace(SavedPlace place) async {
    await _repository.addSavedPlace(place);
    _savedPlaces = [..._savedPlaces, place];
    notifyListeners();
  }
}
