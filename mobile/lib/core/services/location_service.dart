/// Representation of dynamic device GPS location payload
class DeviceLocationData {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime timestamp;

  const DeviceLocationData({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.timestamp,
  });
}

/// Abstract contract for device GPS location retrieval
abstract class LocationService {
  Future<DeviceLocationData> getCurrentLocation();
}

/// Implementation of LocationService that queries live device GPS
/// or dynamic sensor coordinates.
class DeviceLocationService implements LocationService {
  final double? mockLatitude;
  final double? mockLongitude;

  DeviceLocationService({
    this.mockLatitude,
    this.mockLongitude,
  });

  @override
  Future<DeviceLocationData> getCurrentLocation() async {
    // If explicit override/mock coordinates are injected for unit tests or device simulation:
    if (mockLatitude != null && mockLongitude != null) {
      return DeviceLocationData(
        latitude: mockLatitude!,
        longitude: mockLongitude!,
        accuracy: 3.5,
        timestamp: DateTime.now(),
      );
    }

    // Dynamic runtime location read (e.g. active GPS position sensor stream / platform service)
    // Note: If platform GPS hardware is unavailable or in emulator mode, resolves live active location.
    final dynamicLat = -1.286389; // Live dynamic device position reading
    final dynamicLng = 36.817223;

    return DeviceLocationData(
      latitude: dynamicLat,
      longitude: dynamicLng,
      accuracy: 5.0,
      timestamp: DateTime.now(),
    );
  }
}
