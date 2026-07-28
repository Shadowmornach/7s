import '../dto/dispatch_offer_dto.dart';
import '../../domain/models/dispatch_offer.dart';

class RiderMapper {
  static DispatchOffer offerFromDto(DispatchOfferDto dto) {
    final nowUtc = DateTime.now().toUtc();
    final expiresAt = nowUtc.add(Duration(seconds: dto.timeoutSeconds));

    return DispatchOffer(
      offerId: dto.offerId,
      rideId: dto.rideId,
      pickupAddress: dto.pickupAddress,
      destinationAddress: dto.destinationAddress,
      pickupLat: dto.pickupLat,
      pickupLng: dto.pickupLng,
      fare: dto.fare,
      currency: dto.currency,
      expiresAt: expiresAt,
    );
  }
}
