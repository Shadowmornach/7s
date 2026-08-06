import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// 7s Mobile App — Map Service (OpenStreetMap Engine)
/// Decouples OpenStreetMap tile providers, bounding boxes, polyline routes, and custom markers.
class MapService {
  static const String openStreetMapUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String userAgentPackageName = 'com.sevens.mobile';

  /// Standard OpenStreetMap Tile Layer
  static TileLayer buildOpenStreetMapTileLayer() {
    return TileLayer(
      urlTemplate: openStreetMapUrlTemplate,
      userAgentPackageName: userAgentPackageName,
      maxZoom: 19,
    );
  }

  /// Calculates LatLngBounds containing all given coordinates with optional padding
  static LatLngBounds calculateBounds(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLngBounds(
        const LatLng(-3.3967, 38.5562),
        const LatLng(-3.3967, 38.5562),
      );
    }
    return LatLngBounds.fromPoints(points);
  }

  /// Marker for Pickup Point (Green target indicator)
  static Marker buildPickupMarker(LatLng point, {String label = 'Pickup'}) {
    return Marker(
      width: 44,
      height: 44,
      point: point,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: const [
                BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 3)),
              ],
            ),
            child: const Icon(Icons.circle, color: Colors.white, size: 10),
          ),
        ],
      ),
    );
  }

  /// Marker for Destination Point (Orange pin indicator)
  static Marker buildDestinationMarker(LatLng point, {String label = 'Destination'}) {
    return Marker(
      width: 44,
      height: 44,
      point: point,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF7A1A),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: const [
                BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 3)),
              ],
            ),
            child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }

  /// Marker for Live Driver (Motorcycle icon badge)
  static Marker buildDriverMarker(LatLng point, {double heading = 0.0}) {
    return Marker(
      width: 50,
      height: 50,
      point: point,
      child: Transform.rotate(
        angle: heading * (3.141592653589793 / 180),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFF7A1A),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(color: Color(0x40FF7A1A), blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  /// Polyline Layer connecting points along the route
  static PolylineLayer buildRoutePolyline(List<LatLng> points, {Color color = const Color(0xFFFF7A1A)}) {
    return PolylineLayer(
      polylines: [
        Polyline(
          points: points,
          strokeWidth: 4.5,
          color: color,
        ),
      ],
    );
  }
}
