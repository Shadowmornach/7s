class SafetyAlertDto {
  final String alertId;
  final String rideId;
  final String alertType;
  final String status;
  final double latitude;
  final double longitude;
  final String timestampIso;

  const SafetyAlertDto({
    required this.alertId,
    required this.rideId,
    required this.alertType,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.timestampIso,
  });

  factory SafetyAlertDto.fromJson(Map<String, dynamic> json) {
    return SafetyAlertDto(
      alertId: json['alert_id'] as String? ?? '',
      rideId: json['ride_id'] as String? ?? '',
      alertType: json['alert_type'] as String? ?? 'sos',
      status: json['status'] as String? ?? 'dispatched',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      timestampIso: json['timestamp_iso'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alert_id': alertId,
      'ride_id': rideId,
      'alert_type': alertType,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp_iso': timestampIso,
    };
  }
}
