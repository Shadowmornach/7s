import '../models/driver_trip.dart';

abstract class RiderRepository {
  Future<void> toggleOnlineStatus(bool isOnline);

  Future<void> acceptDispatchOffer({
    required String rideId,
    required int expectedVersion,
  });

  Future<void> declineDispatchOffer({
    required String rideId,
    required int expectedVersion,
  });

  Future<DriverTrip> updateTripState({
    required String rideId,
    required int expectedVersion,
    required DriverTripStatus newStatus,
  });
}
