import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/models/fare_quote.dart';
import '../../domain/models/place_location.dart';
import '../../domain/repositories/passenger_repository.dart';

enum PassengerTripState {
  browsing,
  searchingDestination,
  quotingFare,
  selectingPayment,
  matchingDriver,
  driverAssigned,
  rideStarted,
  rideCompleted,
}

class PassengerNotifier extends ChangeNotifier {
  final PassengerRepository _repository;

  PassengerTripState _tripState = PassengerTripState.browsing;
  PlaceLocation? _pickupLocation;
  PlaceLocation? _destinationLocation;
  FareQuote? _currentQuote;
  List<PlaceLocation> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;
  String _selectedPaymentMethodId = 'mpesa';
  String? _activeRideId;
  Timer? _debounceTimer;

  PassengerNotifier({required PassengerRepository repository}) : _repository = repository {
    _pickupLocation = const PlaceLocation(
      placeId: 'p-current',
      primaryText: 'Current location',
      secondaryText: 'Voi Town Center, Kenya',
      latitude: -3.3967,
      longitude: 38.5562,
    );
  }

  void setFixedFareRoute({
    required String destinationTitle,
    required double fareAmount,
    String pickupTitle = 'Current location',
  }) {
    _pickupLocation = PlaceLocation(
      placeId: 'voi-pickup-current',
      primaryText: pickupTitle,
      secondaryText: 'Voi Town Center, Kenya',
      latitude: -3.3967,
      longitude: 38.5562,
    );
    _destinationLocation = PlaceLocation(
      placeId: 'voi-dest-${destinationTitle.toLowerCase().replaceAll(' ', '-')}',
      primaryText: destinationTitle,
      secondaryText: 'Voi Town, Kenya',
      latitude: -3.3980,
      longitude: 38.5580,
    );
    _currentQuote = FareQuote(
      fare: fareAmount,
      currency: 'KSh',
      distanceKm: 5.5,
      etaMinutes: 10,
    );
    _tripState = PassengerTripState.selectingPayment;
    notifyListeners();
  }

  PassengerTripState get tripState => _tripState;
  PlaceLocation? get pickupLocation => _pickupLocation;
  PlaceLocation? get destinationLocation => _destinationLocation;
  FareQuote? get currentQuote => _currentQuote;
  List<PlaceLocation> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String? get searchError => _searchError;
  String get selectedPaymentMethodId => _selectedPaymentMethodId;
  String? get activeRideId => _activeRideId;

  void selectPaymentMethod(String methodId) {
    _selectedPaymentMethodId = methodId;
    notifyListeners();
  }

  /// Amendment 22: 400ms search debouncing to protect mapping egress costs
  void searchPlacesDebounced(String query) {
    _debounceTimer?.cancel();
    _searchError = null;
    if (query.trim().isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      try {
        _searchResults = await _repository.searchPlaces(query);
        _searchError = null;
      } catch (e) {
        _searchResults = [];
        _searchError = 'Place search is currently unavailable (deferred past V1).';
      } finally {
        _isSearching = false;
        notifyListeners();
      }
    });
  }

  Future<void> selectDestination(PlaceLocation destination) async {
    _destinationLocation = destination;
    _tripState = PassengerTripState.quotingFare;
    notifyListeners();

    if (_pickupLocation != null) {
      _currentQuote = await _repository.getFareQuote(
        pickup: _pickupLocation!,
        destination: destination,
      );
      _tripState = PassengerTripState.selectingPayment;
      notifyListeners();
    }
  }

  Future<void> requestRide() async {
    if (_currentQuote == null || _pickupLocation == null || _destinationLocation == null) return;

    _tripState = PassengerTripState.matchingDriver;
    notifyListeners();

    try {
      _activeRideId = await _repository.requestRide(
        quote: _currentQuote!,
        pickup: _pickupLocation!,
        destination: _destinationLocation!,
        paymentMethodId: _selectedPaymentMethodId,
      );
      _tripState = PassengerTripState.driverAssigned;
    } catch (e) {
      _tripState = PassengerTripState.selectingPayment;
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  void resetTrip() {
    _tripState = PassengerTripState.browsing;
    _destinationLocation = null;
    _currentQuote = null;
    _activeRideId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
