class DriverStatusDto {
  final bool isOnline;
  final String status;
  final double currentLat;
  final double currentLng;

  const DriverStatusDto({
    required this.isOnline,
    required this.status,
    required this.currentLat,
    required this.currentLng,
  });

  factory DriverStatusDto.fromJson(Map<String, dynamic> json) {
    return DriverStatusDto(
      isOnline: json['is_online'] as bool? ?? false,
      status: json['status'] as String? ?? 'offline',
      currentLat: (json['current_lat'] as num?)?.toDouble() ?? 0.0,
      currentLng: (json['current_lng'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_online': isOnline,
      'status': status,
      'current_lat': currentLat,
      'current_lng': currentLng,
    };
  }
}
