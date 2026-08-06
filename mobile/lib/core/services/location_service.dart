import 'package:geolocator/geolocator.dart';

/// Representation of dynamic device GPS location payload
class DeviceLocationData {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final String? addressName;
  final DateTime timestamp;

  const DeviceLocationData({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.addressName,
    required this.timestamp,
  });
}

/// Abstract contract for device GPS location retrieval
abstract class LocationService {
  Future<DeviceLocationData> getCurrentLocation();
}

/// Implementation of LocationService that queries live device GPS
/// requesting real location permission from the device.
class DeviceLocationService implements LocationService {
  final double? mockLatitude;
  final double? mockLongitude;

  DeviceLocationService({
    this.mockLatitude,
    this.mockLongitude,
  });

  @override
  Future<DeviceLocationData> getCurrentLocation() async {
    // If explicit override/mock coordinates are injected for unit tests:
    if (mockLatitude != null && mockLongitude != null) {
      return DeviceLocationData(
        latitude: mockLatitude!,
        longitude: mockLongitude!,
        accuracy: 3.5,
        addressName: 'Test Location',
        timestamp: DateTime.now(),
      );
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are disabled on device
        return _fallbackVoiLocation('Location services disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return _fallbackVoiLocation('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return _fallbackVoiLocation('Location permission denied permanently');
      }

      // Fetch real device GPS coordinates
      Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final placeName = _resolveVoiAddressName(pos.latitude, pos.longitude);

      return DeviceLocationData(
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
        addressName: placeName,
        timestamp: pos.timestamp,
      );
    } catch (e) {
      return _fallbackVoiLocation('Voi Town Center');
    }
  }

  static String _resolveVoiAddressName(double lat, double lng) {
    // Check if coordinates are within Voi Town service boundary
    final bool isWithinVoi = lat >= -3.45 && lat <= -3.35 && lng >= 38.50 && lng <= 38.62;

    if (!isWithinVoi) {
      return 'Out of Service Area (Voi Only)';
    }

    // Proximity check for Voi Town Landmarks
    if ((lat - (-3.3980)).abs() < 0.01 && (lng - 38.5600).abs() < 0.01) {
      return 'Voi SGR Station Terminal';
    }
    if ((lat - (-3.3910)).abs() < 0.01 && (lng - 38.5520).abs() < 0.01) {
      return 'Moi County Referral Hospital • Voi';
    }
    if ((lat - (-3.3940)).abs() < 0.01 && (lng - 38.5550).abs() < 0.01) {
      return 'Voi Main Bus Park & Market';
    }
    return 'Voi Town Center • Posta Road';
  }


  DeviceLocationData _fallbackVoiLocation(String placeName) {
    return DeviceLocationData(
      latitude: -3.3967,
      longitude: 38.5562,
      accuracy: 10.0,
      addressName: placeName,
      timestamp: DateTime.now(),
    );
  }
}

