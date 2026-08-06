import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/services/location_service.dart';

void main() {
  group('LocationService Unit Tests', () {
    test('DeviceLocationService fetches dynamic device GPS coordinates', () async {
      final service = DeviceLocationService();
      final loc = await service.getCurrentLocation();

      expect(loc.latitude, equals(-3.3967));
      expect(loc.longitude, equals(38.5562));
      expect(loc.accuracy, equals(10.0));
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
