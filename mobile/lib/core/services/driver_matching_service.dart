import 'dart:math';
import 'package:latlong2/latlong.dart';

/// Representation of a Voi Town Motorcycle Driver
class DriverModel {
  final String id;
  final String fullName;
  final String phone;
  final String photoUrl;
  final String vehiclePlate;
  final String vehicleModel;
  final double rating;
  final int totalTrips;
  final LatLng currentLocation;

  const DriverModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.photoUrl,
    required this.vehiclePlate,
    required this.vehicleModel,
    required this.rating,
    required this.totalTrips,
    required this.currentLocation,
  });
}

/// Service for sorting and assigning nearest available driver in Voi Town
class DriverMatchingService {
  // Operational Geofence for Voi Town, Kenya
  static const double minLat = -3.4500;
  static const double maxLat = -3.3500;
  static const double minLng = 38.5000;
  static const double maxLng = 38.6000;

  /// Validates whether coordinates are within Voi operational scope
  static bool isWithinVoiServiceArea(double lat, double lng) {
    return lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;
  }

  /// Simulated available driver pool around Voi Town landmarks
  static final List<DriverModel> _availableDrivers = [
    const DriverModel(
      id: 'drv_voi_001',
      fullName: 'Francis (Owner / Rider)',
      phone: '+254712345678',
      photoUrl: '',
      vehiclePlate: 'KMCR 777S',
      vehicleModel: 'Toyota Premio',
      rating: 4.9,
      totalTrips: 1420,
      currentLocation: LatLng(-3.3940, 38.5530), // Near Voi SGR Station
    ),
    const DriverModel(
      id: 'drv_voi_002',
      fullName: 'Juma Hassan',
      phone: '+254722987654',
      photoUrl: '',
      vehiclePlate: 'KMDF 123B',
      vehicleModel: 'TVS HLX 150',
      rating: 4.85,
      totalTrips: 890,
      currentLocation: LatLng(-3.3980, 38.5580), // Near Moi Hospital Voi
    ),
    const DriverModel(
      id: 'drv_voi_003',
      fullName: 'Emmanuel Mwangi',
      phone: '+254733456789',
      photoUrl: '',
      vehiclePlate: 'KMCG 456C',
      vehicleModel: 'Boxer BM 150',
      rating: 4.95,
      totalTrips: 2100,
      currentLocation: LatLng(-3.3920, 38.5550), // Near Caltex Petrol Station
    ),
  ];

  /// Calculates Haversine distance between two coordinates in kilometers
  static double calculateHaversineDistanceKm(LatLng p1, LatLng p2) {
    const double r = 6371.0; // Earth radius in km
    final double dLat = _toRadians(p2.latitude - p1.latitude);
    final double dLng = _toRadians(p2.longitude - p1.longitude);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(p1.latitude)) *
            cos(_toRadians(p2.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _toRadians(double degree) => degree * (pi / 180.0);

  /// Sorts available drivers by proximity to pickup point and returns nearest driver
  Future<DriverModel?> findNearestDriver(LatLng pickupPoint) async {
    if (!isWithinVoiServiceArea(pickupPoint.latitude, pickupPoint.longitude)) {
      return null;
    }

    final sortedPool = List<DriverModel>.from(_availableDrivers)
      ..sort((a, b) {
        final distA = calculateHaversineDistanceKm(pickupPoint, a.currentLocation);
        final distB = calculateHaversineDistanceKm(pickupPoint, b.currentLocation);
        return distA.compareTo(distB);
      });

    if (sortedPool.isEmpty) return null;
    return sortedPool.first;
  }
}
