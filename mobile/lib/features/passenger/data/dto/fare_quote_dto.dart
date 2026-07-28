class FareQuoteDto {
  final double fare;
  final String currency;
  final double distanceKm;
  final int etaMinutes;

  const FareQuoteDto({
    required this.fare,
    required this.currency,
    required this.distanceKm,
    required this.etaMinutes,
  });

  factory FareQuoteDto.fromJson(Map<String, dynamic> json) {
    final rawDistance = json['estimated_distance_km'] as num?;
    final rawSeconds = json['estimated_time_seconds'] as int? ?? 300;
    return FareQuoteDto(
      fare: (json['fare'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'KES',
      distanceKm: rawDistance?.toDouble() ?? 0.0,
      etaMinutes: (rawSeconds / 60).round(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fare': fare,
      'currency': currency,
      'distance_km': distanceKm,
      'eta_minutes': etaMinutes,
    };
  }
}
