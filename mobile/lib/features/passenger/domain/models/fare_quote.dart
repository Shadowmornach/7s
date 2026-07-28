class FareQuote {
  final double fare;
  final String currency;
  final double distanceKm;
  final int etaMinutes;

  const FareQuote({
    required this.fare,
    required this.currency,
    required this.distanceKm,
    required this.etaMinutes,
  });

  String get formattedFare => '$currency ${fare.toStringAsFixed(0)}';
}
