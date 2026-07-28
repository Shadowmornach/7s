import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/passenger/data/dto/fare_quote_dto.dart';
import 'package:mobile/features/passenger/data/dto/place_suggestion_dto.dart';
import 'package:mobile/features/passenger/data/mappers/fare_mapper.dart';

void main() {
  group('FareMapper Unit Tests', () {
    test('fromDto correctly maps FareQuoteDto to FareQuote domain model', () {
      const dto = FareQuoteDto(
        fare: 450.0,
        currency: 'KES',
        distanceKm: 8.5,
        etaMinutes: 6,
      );

      final quote = FareMapper.fromDto(dto);

      expect(quote.fare, equals(450.0));
      expect(quote.formattedFare, equals('KES 450'));
    });

    test('placeFromDto correctly maps PlaceSuggestionDto to PlaceLocation domain model', () {
      const dto = PlaceSuggestionDto(
        placeId: 'p-99',
        primaryText: 'Jomo Kenyatta Airport',
        secondaryText: 'Embakasi, Nairobi',
        latitude: -1.3192,
        longitude: 36.9275,
      );

      final location = FareMapper.placeFromDto(dto);

      expect(location.placeId, equals('p-99'));
      expect(location.primaryText, equals('Jomo Kenyatta Airport'));
      expect(location.latitude, equals(-1.3192));
    });
  });
}
