import 'package:latlong2/latlong.dart';

/// Service managing driver position interpolation, route polylines, and dynamic ETA
class RideTrackingService {
  static const double averageSpeedKmh = 30.0; // Average Voi Town Boda/Ride speed

  /// Calculates dynamic ETA in minutes based on remaining distance in kilometers
  static int calculateEtaMinutes(double distanceKm) {
    if (distanceKm <= 0) return 1;
    final minutes = (distanceKm / averageSpeedKmh * 60).round();
    return minutes < 1 ? 1 : minutes;
  }

  /// Generates synthetic intermediate waypoint points between start and end LatLng
  static List<LatLng> generateRoutePoints(LatLng start, LatLng end, {int steps = 20}) {
    final List<LatLng> points = [];
    for (int i = 0; i <= steps; i++) {
      final double fraction = i / steps;
      final double lat = start.latitude + (end.latitude - start.latitude) * fraction;
      final double lng = start.longitude + (end.longitude - start.longitude) * fraction;
      points.add(LatLng(lat, lng));
    }
    return points;
  }

  /// Calculates interpolated position at a specific step fraction (0.0 to 1.0)
  static LatLng interpolatePosition(LatLng start, LatLng end, double fraction) {
    final double lat = start.latitude + (end.latitude - start.latitude) * fraction;
    final double lng = start.longitude + (end.longitude - start.longitude) * fraction;
    return LatLng(lat, lng);
  }
}
