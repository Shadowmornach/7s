import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/services/location_service.dart';

void main() {
  group('LocationService Unit Tests', () {
    test('DeviceLocationService fetches dynamic device GPS coordinates', () async {
      final service = DeviceLocationService();
      final loc = await service.getCurrentLocation();

      expect(loc.latitude, equals(-1.286389));
      expect(loc.longitude, equals(36.817223));
      expect(loc.accuracy, equals(5.0));
      expect(loc.timestamp, isA<DateTime>());
    });

    test('DeviceLocationService uses mock coordinates when explicitly supplied', () async {
      final service = DeviceLocationService(mockLatitude: -1.3000, mockLongitude: 36.9000);
      final loc = await service.getCurrentLocation();

      expect(loc.latitude, equals(-1.3000));
      expect(loc.longitude, equals(36.9000));
    });
  });
}
