import '../models/fare_quote.dart';
import '../models/place_location.dart';

abstract class PassengerRepository {
  Future<List<PlaceLocation>> searchPlaces(String query);

  Future<FareQuote> getFareQuote({
    required PlaceLocation pickup,
    required PlaceLocation destination,
  });

  Future<String> requestRide({
    required FareQuote quote,
    required PlaceLocation pickup,
    required PlaceLocation destination,
    required String paymentMethodId,
  });

  Future<List<Map<String, dynamic>>> getBackendPaymentMethods();
}
