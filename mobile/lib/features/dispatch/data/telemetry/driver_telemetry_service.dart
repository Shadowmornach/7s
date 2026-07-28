import 'dart:async';
import '../../../../core/logging/app_logger.dart';
import '../../domain/models/telemetry_payload.dart';
import '../websocket/dispatch_websocket_client.dart';

enum DriverMotionState { stationary, movingSlowly, rideActive, approachingPickup, offline }

class DriverTelemetryService {
  final DispatchWebSocketClient _wsClient;
  final AppLogger _logger;

  DriverMotionState _motionState = DriverMotionState.offline;
  Timer? _telemetryTimer;

  DriverTelemetryService({
    required DispatchWebSocketClient wsClient,
    required AppLogger logger,
  })  : _wsClient = wsClient,
        _logger = logger;

  DriverMotionState get motionState => _motionState;

  void updateMotionState(DriverMotionState newState) {
    _motionState = newState;
    _logger.info('Telemetry: [driver_motion_state_changed] State: ${newState.name}');
    _configureTelemetryInterval();
  }

  /// OA-02: Adaptive intervals (Stationary 12s, Moving 5s, Active 3s, Pickup 1s, Offline 0s)
  void _configureTelemetryInterval() {
    _telemetryTimer?.cancel();
    if (_motionState == DriverMotionState.offline) return;

    int intervalSeconds;
    switch (_motionState) {
      case DriverMotionState.stationary:
        intervalSeconds = 12;
        break;
      case DriverMotionState.movingSlowly:
        intervalSeconds = 5;
        break;
      case DriverMotionState.rideActive:
        intervalSeconds = 3;
        break;
      case DriverMotionState.approachingPickup:
        intervalSeconds = 1;
        break;
      case DriverMotionState.offline:
        return;
    }

    _telemetryTimer = Timer.periodic(Duration(seconds: intervalSeconds), (timer) {
      final payload = TelemetryPayload(
        latitude: -1.286389,
        longitude: 36.817223,
        heading: 90.0,
        speedKmh: _motionState == DriverMotionState.stationary ? 0.0 : 35.0,
        timestamp: DateTime.now().toUtc(),
      );

      _wsClient.sendPayload(payload.toJson());
    });
  }

  void stopTelemetry() {
    _telemetryTimer?.cancel();
    _motionState = DriverMotionState.offline;
    _logger.info('Telemetry: [driver_telemetry_stopped]');
  }

  void dispose() {
    stopTelemetry();
  }
}
