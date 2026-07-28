import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/features/onboarding/data/storage/onboarding_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingStorage Unit Tests', () {
    test('OnboardingStorage correctly stores and reads onboarding_version int', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final storage = OnboardingStorage();

      expect(await storage.getOnboardingVersion(), equals(0));

      await storage.setOnboardingVersion(1);
      expect(await storage.getOnboardingVersion(), equals(1));
    });
  });
}
