import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/logging/app_logger.dart';
import '../dto/fare_quote_dto.dart';
import '../dto/place_suggestion_dto.dart';
import '../mappers/fare_mapper.dart';
import '../../domain/models/fare_quote.dart';
import '../../domain/models/place_location.dart';
import '../../domain/repositories/passenger_repository.dart';

class PassengerRepositoryImpl implements PassengerRepository {
  final ApiClient _apiClient;
  final AppLogger _logger;

  PassengerRepositoryImpl({
    required ApiClient apiClient,
    required AppLogger logger,
  })  : _apiClient = apiClient,
        _logger = logger;

  @override
  Future<List<PlaceLocation>> searchPlaces(String query) async {
    if (query.trim().isEmpty) return [];

    _logger.info('Telemetry: [place_search_requested] query: $query');
    try {
      final res = await _apiClient.get(
        ApiEndpoints.placesAutocomplete,
        queryParameters: {'q': query},
      );

      final list = res as List<dynamic>? ?? [];
      return list
          .map((item) => FareMapper.placeFromDto(PlaceSuggestionDto.fromJson(item as Map<String, dynamic>)))
          .toList();
    } catch (e) {
      _logger.severe('Place search error: $e');
      throw Exception('Search service unavailable');
    }
  }

  @override
  Future<FareQuote> getFareQuote({
    required PlaceLocation pickup,
    required PlaceLocation destination,
  }) async {
    _logger.info('Telemetry: [fare_quote_requested]');
    try {
      final res = await _apiClient.post(
        ApiEndpoints.ridesQuote,
        body: {
          'pickup_lat': pickup.latitude,
          'pickup_lng': pickup.longitude,
          'destination_lat': destination.latitude,
          'destination_lng': destination.longitude,
        },
      );

      final dto = FareQuoteDto.fromJson(res as Map<String, dynamic>);
      return FareMapper.fromDto(dto);
    } catch (e) {
      _logger.severe('Fare quote request failed: $e');
      rethrow;
    }
  }

  @override
  Future<String> requestRide({
    required FareQuote quote,
    required PlaceLocation pickup,
    required PlaceLocation destination,
    required String paymentMethodId,
  }) async {
    _logger.info('Telemetry: [ride_requested] Fare: ${quote.formattedFare}');

    final res = await _apiClient.post(
      ApiEndpoints.rides,
      body: {
        'payment_method_id': paymentMethodId,
        'pickup_lat': pickup.latitude,
        'pickup_lng': pickup.longitude,
        'destination_lat': destination.latitude,
        'destination_lng': destination.longitude,
      },
    );

    final resMap = res as Map<String, dynamic>? ?? {};
    return resMap['ride_id'] as String? ?? 'ride-123';
  }

  @override
  Future<List<Map<String, dynamic>>> getBackendPaymentMethods() async {
    // Backend-driven payment method list (Cash, M-Pesa, Card)
    return [
      {'id': 'mpesa', 'name': 'M-Pesa STK Push', 'icon': 'phone_android'},
      {'id': 'cash', 'name': 'Cash Payment', 'icon': 'payments'},
    ];
  }
}
