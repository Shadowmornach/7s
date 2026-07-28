class DispatchOfferDto {
  final String offerId;
  final String rideId;
  final String pickupAddress;
  final String destinationAddress;
  final double pickupLat;
  final double pickupLng;
  final double fare;
  final String currency;
  final int timeoutSeconds;

  const DispatchOfferDto({
    required this.offerId,
    required this.rideId,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.fare,
    required this.currency,
    required this.timeoutSeconds,
  });

  factory DispatchOfferDto.fromJson(Map<String, dynamic> json) {
    return DispatchOfferDto(
      offerId: json['offer_id'] as String? ?? '',
      rideId: json['ride_id'] as String? ?? '',
      pickupAddress: json['pickup_address'] as String? ?? '',
      destinationAddress: json['destination_address'] as String? ?? '',
      pickupLat: (json['pickup_lat'] as num?)?.toDouble() ?? 0.0,
      pickupLng: (json['pickup_lng'] as num?)?.toDouble() ?? 0.0,
      fare: (json['fare'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'KES',
      timeoutSeconds: json['timeout_seconds'] as int? ?? 15,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'offer_id': offerId,
      'ride_id': rideId,
      'pickup_address': pickupAddress,
      'destination_address': destinationAddress,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'fare': fare,
      'currency': currency,
      'timeout_seconds': timeoutSeconds,
    };
  }
}
