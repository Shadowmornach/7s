enum DriverTripStatus {
  accepted,
  navigatingToPickup,
  arrivedAtPickup,
  inProgress,
  completed,
}

class DriverTrip {
  final String rideId;
  final String pickupAddress;
  final String destinationAddress;
  final double fare;
  final String currency;
  final DriverTripStatus status;

  const DriverTrip({
    required this.rideId,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.fare,
    required this.currency,
    required this.status,
  });

  String get formattedFare => '$currency ${fare.toStringAsFixed(0)}';
}
