import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/rider/data/dto/dispatch_offer_dto.dart';
import 'package:mobile/features/rider/data/mappers/rider_mapper.dart';

void main() {
  group('RiderMapper Unit Tests', () {
    test('offerFromDto maps DispatchOfferDto to DispatchOffer domain model with 15s expiration', () {
      const dto = DispatchOfferDto(
        offerId: 'off-100',
        rideId: 'ride-200',
        pickupAddress: 'Kenyatta Avenue',
        destinationAddress: 'Westlands',
        pickupLat: -1.2863,
        pickupLng: 36.8172,
        fare: 500.0,
        currency: 'KES',
        timeoutSeconds: 15,
      );

      final offer = RiderMapper.offerFromDto(dto);

      expect(offer.offerId, equals('off-100'));
      expect(offer.rideId, equals('ride-200'));
      expect(offer.formattedFare, equals('KES 500'));
      expect(offer.isExpired, isFalse);
    });
  });
}
