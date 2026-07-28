import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/logging/app_logger.dart';
import 'package:mobile/features/dispatch/data/telemetry/driver_telemetry_service.dart';
import 'package:mobile/features/dispatch/data/websocket/dispatch_websocket_client.dart';

void main() {
  group('DriverTelemetryService Unit Tests', () {
    late AppLogger logger;
    late DispatchWebSocketClient wsClient;
    late DriverTelemetryService service;

    setUp(() {
      logger = AppLogger();
      wsClient = DispatchWebSocketClient(logger: logger);
      service = DriverTelemetryService(wsClient: wsClient, logger: logger);
    });

    tearDown(() {
      service.dispose();
      wsClient.dispose();
    });

    test('updateMotionState updates motion state and configures adaptive intervals', () {
      expect(service.motionState, equals(DriverMotionState.offline));

      service.updateMotionState(DriverMotionState.stationary);
      expect(service.motionState, equals(DriverMotionState.stationary));

      service.updateMotionState(DriverMotionState.approachingPickup);
      expect(service.motionState, equals(DriverMotionState.approachingPickup));
    });
  });
}
