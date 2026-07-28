import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/services/location_service.dart';
import '../../domain/models/safety_alert.dart';
import '../../domain/models/emergency_contact.dart';
import '../../domain/repositories/safety_repository.dart';

class SafetyNotifier extends ChangeNotifier {
  final SafetyRepository _repository;
  final LocationService _locationService;
  final ConnectivityService _connectivityService;

  SafetyAlert? _activeAlert;
  List<EmergencyContact> _contacts = [];
  String? _shareUrl;
  bool _isLoading = false;

  StreamSubscription<ConnectivityStatus>? _connectivitySub;

  SafetyNotifier({
    required SafetyRepository repository,
    required ConnectivityService connectivityService,
    LocationService? locationService,
  })  : _repository = repository,
        _connectivityService = connectivityService,
        _locationService = locationService ?? DeviceLocationService() {
    _init();
  }

  SafetyAlert? get activeAlert => _activeAlert;
  List<EmergencyContact> get contacts => _contacts;
  String? get shareUrl => _shareUrl;
  bool get isLoading => _isLoading;

  /// Called once on construction.
  /// (1) Checks connectivity immediately — if already online, replay any queued SOS.
  /// (2) Subscribes to future connectivity changes for ongoing reconnect retries.
  void _init() {
    // Immediate check: app may have started online after a prior offline session.
    _connectivityService.checkConnectivity().then((status) {
      if (status == ConnectivityStatus.online) {
        _replayPendingSos();
      }
    });

    // Ongoing: replay on every transition to online.
    _connectivitySub = _connectivityService.onConnectivityChanged.listen((status) {
      if (status == ConnectivityStatus.online) {
        _replayPendingSos();
      }
    });
  }

  /// Attempts to dispatch a queued offline SOS. Silent on failure (still offline).
  /// Updates [_activeAlert] only if the retry lands successfully.
  Future<void> _replayPendingSos() async {
    final dispatched = await _repository.retryPendingSos();
    if (dispatched != null) {
      _activeAlert = dispatched;
      notifyListeners();
    }
  }

  Future<void> triggerSos({
    required String rideId,
    required int expectedVersion,
    double? latitude,
    double? longitude,
    required String emergencyType,
    required String severity,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final double targetLat;
      final double targetLng;

      if (latitude != null && longitude != null) {
        targetLat = latitude;
        targetLng = longitude;
      } else {
        final locData = await _locationService.getCurrentLocation();
        targetLat = locData.latitude;
        targetLng = locData.longitude;
      }

      _activeAlert = await _repository.triggerSosAlert(
        rideId: rideId,
        expectedVersion: expectedVersion,
        latitude: targetLat,
        longitude: targetLng,
        emergencyType: emergencyType,
        severity: severity,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadContacts() async {
    _contacts = await _repository.getEmergencyContacts();
    notifyListeners();
  }

  Future<void> addContact(EmergencyContact contact) async {
    await _repository.addEmergencyContact(contact);
    _contacts = [..._contacts, contact];
    notifyListeners();
  }

  Future<void> generateShareLink(String rideId) async {
    _shareUrl = await _repository.getShareableTripLink(rideId);
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}
