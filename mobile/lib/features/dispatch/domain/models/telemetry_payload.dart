class TelemetryPayload {
  final double latitude;
  final double longitude;
  final double heading;
  final double speedKmh;
  final DateTime timestamp;

  const TelemetryPayload({
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.speedKmh,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'lat': latitude,
      'lng': longitude,
      'heading': heading,
      'speed_kmh': speedKmh,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
