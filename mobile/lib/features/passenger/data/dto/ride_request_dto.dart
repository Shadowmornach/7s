class RideRequestDto {
  final String idempotencyKey;
  final String paymentMethodId;
  final double pickupLat;
  final double pickupLng;
  final double destinationLat;
  final double destinationLng;

  const RideRequestDto({
    required this.idempotencyKey,
    required this.paymentMethodId,
    required this.pickupLat,
    required this.pickupLng,
    required this.destinationLat,
    required this.destinationLng,
  });

  Map<String, dynamic> toJson() {
    return {
      'idempotency_key': idempotencyKey,
      'payment_method_id': paymentMethodId,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'destination_lat': destinationLat,
      'destination_lng': destinationLng,
    };
  }
}
