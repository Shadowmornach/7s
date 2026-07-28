import 'package:flutter/foundation.dart';
import '../../domain/models/dispatch_offer.dart';
import '../../domain/models/driver_trip.dart';
import '../../domain/repositories/rider_repository.dart';

class RiderNotifier extends ChangeNotifier {
  final RiderRepository _repository;

  bool _isOnline = false;
  DispatchOffer? _activeOffer;
  DriverTrip? _activeTrip;

  RiderNotifier({required RiderRepository repository}) : _repository = repository;

  bool get isOnline => _isOnline;
  DispatchOffer? get activeOffer => _activeOffer;
  DriverTrip? get activeTrip => _activeTrip;

  Future<void> toggleOnline() async {
    _isOnline = !_isOnline;
    await _repository.toggleOnlineStatus(_isOnline);
    if (!_isOnline) {
      _activeOffer = null;
      _activeTrip = null;
    }
    notifyListeners();
  }

  void simulateIncomingOffer(DispatchOffer offer) {
    if (!_isOnline) return;
    _activeOffer = offer;
    notifyListeners();
  }

  Future<void> acceptOffer() async {
    if (_activeOffer == null) return;
    final offer = _activeOffer!;
    await _repository.acceptDispatchOffer(
      rideId: offer.rideId,
      expectedVersion: 1,
    );

    _activeTrip = DriverTrip(
      rideId: offer.rideId,
      pickupAddress: offer.pickupAddress,
      destinationAddress: offer.destinationAddress,
      fare: offer.fare,
      currency: offer.currency,
      status: DriverTripStatus.accepted,
    );
    _activeOffer = null;
    notifyListeners();
  }

  Future<void> declineOffer() async {
    if (_activeOffer == null) return;
    await _repository.declineDispatchOffer(
      rideId: _activeOffer!.rideId,
      expectedVersion: 1,
    );
    _activeOffer = null;
    notifyListeners();
  }

  Future<void> advanceTripState() async {
    if (_activeTrip == null) return;

    DriverTripStatus nextStatus;
    switch (_activeTrip!.status) {
      case DriverTripStatus.accepted:
        nextStatus = DriverTripStatus.navigatingToPickup;
        break;
      case DriverTripStatus.navigatingToPickup:
        nextStatus = DriverTripStatus.arrivedAtPickup;
        break;
      case DriverTripStatus.arrivedAtPickup:
        nextStatus = DriverTripStatus.inProgress;
        break;
      case DriverTripStatus.inProgress:
        nextStatus = DriverTripStatus.completed;
        break;
      case DriverTripStatus.completed:
        _activeTrip = null;
        notifyListeners();
        return;
    }

    _activeTrip = await _repository.updateTripState(
      rideId: _activeTrip!.rideId,
      expectedVersion: 1,
      newStatus: nextStatus,
    );
    notifyListeners();
  }
}
