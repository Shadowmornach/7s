class DispatchOffer {
  final String offerId;
  final String rideId;
  final String pickupAddress;
  final String destinationAddress;
  final double pickupLat;
  final double pickupLng;
  final double fare;
  final String currency;
  final DateTime expiresAt;

  const DispatchOffer({
    required this.offerId,
    required this.rideId,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.fare,
    required this.currency,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);

  String get formattedFare => '$currency ${fare.toStringAsFixed(0)}';
}
