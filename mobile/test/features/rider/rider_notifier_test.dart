import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/rider/domain/models/dispatch_offer.dart';
import 'package:mobile/features/rider/domain/models/driver_trip.dart';
import 'package:mobile/features/rider/domain/repositories/rider_repository.dart';
import 'package:mobile/features/rider/presentation/providers/rider_provider.dart';

class MockRiderRepository implements RiderRepository {
  @override
  Future<void> toggleOnlineStatus(bool isOnline) async {}

  @override
  Future<void> acceptDispatchOffer({
    required String rideId,
    required int expectedVersion,
  }) async {}

  @override
  Future<void> declineDispatchOffer({
    required String rideId,
    required int expectedVersion,
  }) async {}

  @override
  Future<DriverTrip> updateTripState({
    required String rideId,
    required int expectedVersion,
    required DriverTripStatus newStatus,
  }) async {
    return DriverTrip(
      rideId: rideId,
      pickupAddress: 'Kenyatta Avenue',
      destinationAddress: 'Westlands',
      fare: 400.0,
      currency: 'KES',
      status: newStatus,
    );
  }
}

void main() {
  group('RiderNotifier Unit Tests', () {
    late MockRiderRepository repo;

    setUp(() {
      repo = MockRiderRepository();
    });

    test('toggleOnline updates status and clears active state when going offline', () async {
      final notifier = RiderNotifier(repository: repo);

      expect(notifier.isOnline, isFalse);
      await notifier.toggleOnline();
      expect(notifier.isOnline, isTrue);

      await notifier.toggleOnline();
      expect(notifier.isOnline, isFalse);
    });

    test('acceptOffer creates activeTrip in accepted state', () async {
      final notifier = RiderNotifier(repository: repo);
      await notifier.toggleOnline();

      final offer = DispatchOffer(
        offerId: 'off-1',
        rideId: 'ride-1',
        pickupAddress: 'Pickup Point',
        destinationAddress: 'Dropoff Point',
        pickupLat: -1.28,
        pickupLng: 36.81,
        fare: 350.0,
        currency: 'KES',
        expiresAt: DateTime.now().toUtc().add(const Duration(seconds: 15)),
      );

      notifier.simulateIncomingOffer(offer);
      expect(notifier.activeOffer, equals(offer));

      await notifier.acceptOffer();
      expect(notifier.activeOffer, isNull);
      expect(notifier.activeTrip, isNotNull);
      expect(notifier.activeTrip!.status, equals(DriverTripStatus.accepted));
    });

    test('advanceTripState progresses through state machine', () async {
      final notifier = RiderNotifier(repository: repo);
      await notifier.toggleOnline();

      final offer = DispatchOffer(
        offerId: 'off-1',
        rideId: 'ride-1',
        pickupAddress: 'Pickup Point',
        destinationAddress: 'Dropoff Point',
        pickupLat: -1.28,
        pickupLng: 36.81,
        fare: 350.0,
        currency: 'KES',
        expiresAt: DateTime.now().toUtc().add(const Duration(seconds: 15)),
      );
      notifier.simulateIncomingOffer(offer);
      await notifier.acceptOffer();

      await notifier.advanceTripState(); // navigatingToPickup
      expect(notifier.activeTrip!.status, equals(DriverTripStatus.navigatingToPickup));

      await notifier.advanceTripState(); // arrivedAtPickup
      expect(notifier.activeTrip!.status, equals(DriverTripStatus.arrivedAtPickup));

      await notifier.advanceTripState(); // inProgress
      expect(notifier.activeTrip!.status, equals(DriverTripStatus.inProgress));

      await notifier.advanceTripState(); // completed
      expect(notifier.activeTrip!.status, equals(DriverTripStatus.completed));

      await notifier.advanceTripState(); // done -> clears activeTrip
      expect(notifier.activeTrip, isNull);
    });
  });
}
