import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/passenger/domain/models/fare_quote.dart';
import 'package:mobile/features/passenger/domain/models/place_location.dart';
import 'package:mobile/features/passenger/domain/repositories/passenger_repository.dart';
import 'package:mobile/features/passenger/presentation/providers/passenger_provider.dart';

class MockPassengerRepository implements PassengerRepository {
  @override
  Future<List<PlaceLocation>> searchPlaces(String query) async {
    return const [
      PlaceLocation(
        placeId: 'p1',
        primaryText: 'Nairobi CBD',
        secondaryText: 'Kenyatta Avenue',
        latitude: -1.286389,
        longitude: 36.817223,
      ),
    ];
  }

  @override
  Future<FareQuote> getFareQuote({required PlaceLocation pickup, required PlaceLocation destination}) async {
    return const FareQuote(
      fare: 300.0,
      currency: 'KES',
      distanceKm: 4.0,
      etaMinutes: 3,
    );
  }

  @override
  Future<String> requestRide({
    required FareQuote quote,
    required PlaceLocation pickup,
    required PlaceLocation destination,
    required String paymentMethodId,
  }) async {
    return 'ride-mock-789';
  }

  @override
  Future<List<Map<String, dynamic>>> getBackendPaymentMethods() async {
    return [
      {'id': 'mpesa', 'name': 'M-Pesa'},
      {'id': 'cash', 'name': 'Cash'},
    ];
  }
}

void main() {
  group('PassengerNotifier Unit Tests', () {
    late MockPassengerRepository repo;

    setUp(() {
      repo = MockPassengerRepository();
    });

    test('selectDestination triggers quote fetch and transitions to selectingPayment state', () async {
      final notifier = PassengerNotifier(repository: repo);

      const dest = PlaceLocation(
        placeId: 'p2',
        primaryText: 'Westlands',
        secondaryText: 'Waiyaki Way',
        latitude: -1.2676,
        longitude: 36.8121,
      );

      await notifier.selectDestination(dest);

      expect(notifier.destinationLocation, equals(dest));
      expect(notifier.currentQuote, isNotNull);
      expect(notifier.currentQuote!.fare, equals(300.0));
      expect(notifier.tripState, equals(PassengerTripState.selectingPayment));
    });

    test('requestRide transitions to driverAssigned state', () async {
      final notifier = PassengerNotifier(repository: repo);
      const dest = PlaceLocation(
        placeId: 'p2',
        primaryText: 'Westlands',
        secondaryText: 'Waiyaki Way',
        latitude: -1.2676,
        longitude: 36.8121,
      );
      await notifier.selectDestination(dest);

      await notifier.requestRide();

      expect(notifier.activeRideId, equals('ride-mock-789'));
      expect(notifier.tripState, equals(PassengerTripState.driverAssigned));
    });
  });
}
