import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/services/driver_matching_service.dart';
import '../../../../core/services/ride_tracking_service.dart';

/// Comprehensive Ride Lifecycle Status Enum matching Supabase Schema
enum RideLifecycleStatus {
  idle,
  requested,
  matching,
  matched,
  accepted,
  arriving,
  arrived,
  passengerOnboard,
  inProgress,
  completed,
  cancelledByCustomer,
  cancelledByDriver,
  noDriverFound,
  expired,
}

/// Representation of an Event Audit Log Item in the Ride Event Timeline
class RideEventLogItem {
  final String id;
  final RideLifecycleStatus status;
  final String note;
  final DateTime timestamp;

  const RideEventLogItem({
    required this.id,
    required this.status,
    required this.note,
    required this.timestamp,
  });
}

/// Active Ride Booking Request Model
class ActiveRideBooking {
  final String id;
  final String pickupName;
  final LatLng pickupLatLng;
  final String destinationName;
  final LatLng destinationLatLng;
  final String fareAmount;
  final String paymentMethod;
  final RideLifecycleStatus status;
  final DriverModel? assignedDriver;
  final LatLng? driverPosition;
  final int etaMinutes;
  final double distanceRemainingKm;
  final List<LatLng> routePoints;
  final List<RideEventLogItem> eventLogs;
  final DateTime createdAt;

  const ActiveRideBooking({
    required this.id,
    required this.pickupName,
    required this.pickupLatLng,
    required this.destinationName,
    required this.destinationLatLng,
    required this.fareAmount,
    required this.paymentMethod,
    required this.status,
    this.assignedDriver,
    this.driverPosition,
    this.etaMinutes = 0,
    this.distanceRemainingKm = 0.0,
    this.routePoints = const [],
    this.eventLogs = const [],
    required this.createdAt,
  });

  ActiveRideBooking copyWith({
    RideLifecycleStatus? status,
    DriverModel? assignedDriver,
    LatLng? driverPosition,
    int? etaMinutes,
    double? distanceRemainingKm,
    List<LatLng>? routePoints,
    List<RideEventLogItem>? eventLogs,
  }) {
    return ActiveRideBooking(
      id: id,
      pickupName: pickupName,
      pickupLatLng: pickupLatLng,
      destinationName: destinationName,
      destinationLatLng: destinationLatLng,
      fareAmount: fareAmount,
      paymentMethod: paymentMethod,
      status: status ?? this.status,
      assignedDriver: assignedDriver ?? this.assignedDriver,
      driverPosition: driverPosition ?? this.driverPosition,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      distanceRemainingKm: distanceRemainingKm ?? this.distanceRemainingKm,
      routePoints: routePoints ?? this.routePoints,
      eventLogs: eventLogs ?? this.eventLogs,
      createdAt: createdAt,
    );
  }
}

/// ChangeNotifier Notifier for Ride Lifecycle State Management
class RideStateNotifier extends ChangeNotifier {
  ActiveRideBooking? _activeBooking;
  Timer? _simulationTimer;
  Timer? _searchTimeoutTimer;

  ActiveRideBooking? get activeBooking => _activeBooking;
  RideLifecycleStatus get currentStatus => _activeBooking?.status ?? RideLifecycleStatus.idle;

  final DriverMatchingService _matchingService = DriverMatchingService();

  /// Starts a new Ride Request immediately creating the DB payload and initiating matching
  Future<bool> startRideBooking({
    required String pickupName,
    required LatLng pickupLatLng,
    required String destinationName,
    required LatLng destinationLatLng,
    required String fareAmount,
    required String paymentMethod,
  }) async {
    // 1. Geofence Validation: Ensure pickup & destination are inside Voi Town
    if (!DriverMatchingService.isWithinVoiServiceArea(pickupLatLng.latitude, pickupLatLng.longitude) ||
        !DriverMatchingService.isWithinVoiServiceArea(destinationLatLng.latitude, destinationLatLng.longitude)) {
      _activeBooking = ActiveRideBooking(
        id: 'req_${DateTime.now().millisecondsSinceEpoch}',
        pickupName: pickupName,
        pickupLatLng: pickupLatLng,
        destinationName: destinationName,
        destinationLatLng: destinationLatLng,
        fareAmount: fareAmount,
        paymentMethod: paymentMethod,
        status: RideLifecycleStatus.noDriverFound,
        createdAt: DateTime.now(),
        eventLogs: [
          RideEventLogItem(
            id: 'log_0',
            status: RideLifecycleStatus.noDriverFound,
            note: '7s currently operates only within Voi Town.',
            timestamp: DateTime.now(),
          ),
        ],
      );
      notifyListeners();
      return false;
    }

    final requestId = 'req_7s_${DateTime.now().millisecondsSinceEpoch}';
    final initialLog = RideEventLogItem(
      id: 'log_1',
      status: RideLifecycleStatus.requested,
      note: 'Ride request created and saved to database.',
      timestamp: DateTime.now(),
    );

    // 2. Immediately create ride request record with REQUESTED status
    _activeBooking = ActiveRideBooking(
      id: requestId,
      pickupName: pickupName,
      pickupLatLng: pickupLatLng,
      destinationName: destinationName,
      destinationLatLng: destinationLatLng,
      fareAmount: fareAmount,
      paymentMethod: paymentMethod,
      status: RideLifecycleStatus.requested,
      eventLogs: [initialLog],
      createdAt: DateTime.now(),
    );
    notifyListeners();

    // 3. Initiate Driver Matching
    _transitionStatus(
      RideLifecycleStatus.matching,
      'Searching for nearest available motorcycle rider in Voi...',
    );

    // Start 30-Second Search Timeout
    _searchTimeoutTimer?.cancel();
    _searchTimeoutTimer = Timer(const Duration(seconds: 30), () {
      if (_activeBooking?.status == RideLifecycleStatus.matching) {
        _transitionStatus(
          RideLifecycleStatus.noDriverFound,
          'No drivers accepted within 30 seconds. Try again or adjust location.',
        );
      }
    });

    // 4. Find Nearest Driver
    final nearestDriver = await _matchingService.findNearestDriver(pickupLatLng);
    if (nearestDriver == null) {
      _searchTimeoutTimer?.cancel();
      _transitionStatus(
        RideLifecycleStatus.noDriverFound,
        'No nearby drivers currently online in Voi Town.',
      );
      return false;
    }

    // 5. Simulate Driver Acceptance (Nearest driver accepts after 2.5 seconds)
    await Future.delayed(const Duration(milliseconds: 2500));
    _searchTimeoutTimer?.cancel();

    if (_activeBooking?.status == RideLifecycleStatus.matching ||
        _activeBooking?.status == RideLifecycleStatus.requested) {
      _transitionStatus(
        RideLifecycleStatus.matched,
        'Driver matched: ${nearestDriver.fullName} (${nearestDriver.vehiclePlate}).',
      );

      // Attach Assigned Driver
      _activeBooking = _activeBooking?.copyWith(
        assignedDriver: nearestDriver,
        driverPosition: nearestDriver.currentLocation,
      );
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 1200));

      // Driver Accepts
      _transitionStatus(
        RideLifecycleStatus.accepted,
        'Driver ${nearestDriver.fullName} accepted ride request.',
      );

      // Transition to Driver En Route
      _startDriverEnRouteSimulation();
    }

    return true;
  }

  /// Manages simulated driver movement towards pickup, arriving, and ride in progress
  void _startDriverEnRouteSimulation() {
    if (_activeBooking == null || _activeBooking!.assignedDriver == null) return;

    _transitionStatus(
      RideLifecycleStatus.arriving,
      'Driver is en route to pickup point (${_activeBooking!.pickupName}).',
    );

    final startPoint = _activeBooking!.assignedDriver!.currentLocation;
    final pickupPoint = _activeBooking!.pickupLatLng;
    final destPoint = _activeBooking!.destinationLatLng;

    // Generate Route Points for Driver to Pickup
    final enRoutePoints = RideTrackingService.generateRoutePoints(startPoint, pickupPoint, steps: 10);
    int currentStep = 0;

    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_activeBooking == null) {
        timer.cancel();
        return;
      }

      if (currentStep < enRoutePoints.length) {
        final pos = enRoutePoints[currentStep];
        final dist = DriverMatchingService.calculateHaversineDistanceKm(pos, pickupPoint);
        final eta = RideTrackingService.calculateEtaMinutes(dist);

        _activeBooking = _activeBooking?.copyWith(
          driverPosition: pos,
          distanceRemainingKm: dist,
          etaMinutes: eta,
          routePoints: enRoutePoints.sublist(currentStep),
        );
        notifyListeners();
        currentStep++;
      } else {
        // Driver Arrived at Pickup!
        timer.cancel();
        _transitionStatus(
          RideLifecycleStatus.arrived,
          'Driver has arrived at pickup point (${_activeBooking!.pickupName}).',
        );

        // Start Ride In Progress after passenger onboard delay
        Future.delayed(const Duration(seconds: 3), () {
          _startRideInProgressSimulation(pickupPoint, destPoint);
        });
      }
    });
  }

  void _startRideInProgressSimulation(LatLng pickupPoint, LatLng destPoint) {
    _transitionStatus(
      RideLifecycleStatus.passengerOnboard,
      'Passenger boarded motorcycle.',
    );

    _transitionStatus(
      RideLifecycleStatus.inProgress,
      'Ride in progress towards ${_activeBooking!.destinationName}.',
    );

    final tripPoints = RideTrackingService.generateRoutePoints(pickupPoint, destPoint, steps: 12);
    int currentStep = 0;

    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_activeBooking == null) {
        timer.cancel();
        return;
      }

      if (currentStep < tripPoints.length) {
        final pos = tripPoints[currentStep];
        final dist = DriverMatchingService.calculateHaversineDistanceKm(pos, destPoint);
        final eta = RideTrackingService.calculateEtaMinutes(dist);

        _activeBooking = _activeBooking?.copyWith(
          driverPosition: pos,
          distanceRemainingKm: dist,
          etaMinutes: eta,
          routePoints: tripPoints.sublist(currentStep),
        );
        notifyListeners();
        currentStep++;
      } else {
        // Ride Completed!
        timer.cancel();
        _transitionStatus(
          RideLifecycleStatus.completed,
          'Ride completed successfully. Destination reached!',
        );
      }
    });
  }

  /// Cancels active ride request
  void cancelRide({String reason = 'Canceled by Customer'}) {
    _simulationTimer?.cancel();
    _searchTimeoutTimer?.cancel();
    _transitionStatus(
      RideLifecycleStatus.cancelledByCustomer,
      'Ride request canceled. Reason: $reason',
    );
  }

  /// Resets state back to idle
  void reset() {
    _simulationTimer?.cancel();
    _searchTimeoutTimer?.cancel();
    _activeBooking = null;
    notifyListeners();
  }

  void _transitionStatus(RideLifecycleStatus newStatus, String note) {
    if (_activeBooking == null) return;
    final log = RideEventLogItem(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      status: newStatus,
      note: note,
      timestamp: DateTime.now(),
    );
    final updatedLogs = List<RideEventLogItem>.from(_activeBooking!.eventLogs)..add(log);
    _activeBooking = _activeBooking?.copyWith(
      status: newStatus,
      eventLogs: updatedLogs,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _searchTimeoutTimer?.cancel();
    super.dispose();
  }
}
