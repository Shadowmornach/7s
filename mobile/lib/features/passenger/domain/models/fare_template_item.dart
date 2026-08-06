/// Domain Model representing a Voi Town Fare Template
class FareTemplateItem {
  final String id;
  final String routeTitle;
  final String pickupName;
  final String pickupAddress;
  final String destinationName;
  final String destinationAddress;
  final double fare;
  final double estimatedDistanceKm;
  final int estimatedTimeMins;
  final String notes;

  const FareTemplateItem({
    required this.id,
    required this.routeTitle,
    required this.pickupName,
    required this.pickupAddress,
    required this.destinationName,
    required this.destinationAddress,
    required this.fare,
    required this.estimatedDistanceKm,
    required this.estimatedTimeMins,
    required this.notes,
  });

  String get formattedFare => 'KSh ${fare.toStringAsFixed(0)}';

  FareTemplateItem copyWith({double? fare, String? notes}) {
    return FareTemplateItem(
      id: id,
      routeTitle: routeTitle,
      pickupName: pickupName,
      pickupAddress: pickupAddress,
      destinationName: destinationName,
      destinationAddress: destinationAddress,
      fare: fare ?? this.fare,
      estimatedDistanceKm: estimatedDistanceKm,
      estimatedTimeMins: estimatedTimeMins,
      notes: notes ?? this.notes,
    );
  }
}
