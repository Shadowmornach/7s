import '../dto/fare_quote_dto.dart';
import '../dto/place_suggestion_dto.dart';
import '../../domain/models/fare_quote.dart';
import '../../domain/models/place_location.dart';

class FareMapper {
  static FareQuote fromDto(FareQuoteDto dto) {
    return FareQuote(
      fare: dto.fare,
      currency: dto.currency,
      distanceKm: dto.distanceKm,
      etaMinutes: dto.etaMinutes,
    );
  }

  static PlaceLocation placeFromDto(PlaceSuggestionDto dto) {
    return PlaceLocation(
      placeId: dto.placeId,
      primaryText: dto.primaryText,
      secondaryText: dto.secondaryText,
      latitude: dto.latitude,
      longitude: dto.longitude,
    );
  }
}
