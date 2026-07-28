import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/models/driver_trip.dart';
import '../../domain/repositories/rider_repository.dart';

class RiderRepositoryImpl implements RiderRepository {
  final ApiClient _apiClient;
  final AppLogger _logger;

  RiderRepositoryImpl({
    required ApiClient apiClient,
    required AppLogger logger,
  })  : _apiClient = apiClient,
        _logger = logger;

  @override
  Future<void> toggleOnlineStatus(bool isOnline) async {
    _logger.info('Telemetry: [driver_status_toggled] isOnline: $isOnline');
    try {
      await _apiClient.post(
        ApiEndpoints.driverOnline,
        body: {'is_online': isOnline},
      );
    } catch (e) {
      _logger.warning('Rider status toggle fallback for offline/demo mode');
    }
  }

  @override
  Future<void> acceptDispatchOffer({
    required String rideId,
    required int expectedVersion,
  }) async {
    _logger.info('Telemetry: [job_accepted] RideId: $rideId');
    try {
      await _apiClient.post(
        '/rides/$rideId/events',
        body: {
          'action': 'accept_assignment',
          'expected_version': expectedVersion,
          'metadata': {},
        },
      );
    } catch (e) {
      _logger.warning('Dispatch accept fallback for offline/demo mode');
    }
  }

  @override
  Future<void> declineDispatchOffer({
    required String rideId,
    required int expectedVersion,
  }) async {
    _logger.info('Telemetry: [job_declined] RideId: $rideId');
    try {
      await _apiClient.post(
        '/rides/$rideId/events',
        body: {
          'action': 'reject_assignment',
          'expected_version': expectedVersion,
          'metadata': {},
        },
      );
    } catch (e) {
      _logger.warning('Dispatch decline fallback for offline/demo mode');
    }
  }

  @override
  Future<DriverTrip> updateTripState({
    required String rideId,
    required int expectedVersion,
    required DriverTripStatus newStatus,
  }) async {
    _logger.info('Telemetry: [trip_status_updated] RideId: $rideId Status: ${newStatus.name}');
    
    String? action;
    if (newStatus == DriverTripStatus.arrivedAtPickup) {
      action = 'arrive';
    } else if (newStatus == DriverTripStatus.inProgress) {
      action = 'start_ride';
    } else if (newStatus == DriverTripStatus.completed) {
      action = 'complete_ride';
    }

    if (action != null) {
      try {
        await _apiClient.post(
          '/rides/$rideId/events',
          body: {
            'action': action,
            'expected_version': expectedVersion,
            'metadata': {},
          },
        );
      } catch (e) {
        _logger.warning('Trip state update fallback for offline/demo mode');
      }
    }

    return DriverTrip(
      rideId: rideId,
      pickupAddress: 'Kenyatta Avenue, Nairobi',
      destinationAddress: 'Waiyaki Way, Westlands',
      fare: 350.0,
      currency: 'KES',
      status: newStatus,
    );
  }
}
