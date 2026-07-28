import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OnboardingStorage {
  static const String _onboardingVersionKey = '7s_onboarding_version';
  final FlutterSecureStorage _storage;

  OnboardingStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<int> getOnboardingVersion() async {
    final val = await _storage.read(key: _onboardingVersionKey);
    if (val == null) return 0;
    return int.tryParse(val) ?? 0;
  }

  Future<void> setOnboardingVersion(int version) async {
    await _storage.write(key: _onboardingVersionKey, value: version.toString());
  }

  Future<void> clearOnboardingVersion() async {
    await _storage.delete(key: _onboardingVersionKey);
  }
}
