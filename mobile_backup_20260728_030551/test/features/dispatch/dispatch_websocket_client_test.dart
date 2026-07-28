import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/logging/app_logger.dart';
import 'package:mobile/features/dispatch/data/websocket/dispatch_websocket_client.dart';

void main() {
  group('DispatchWebSocketClient Unit Tests', () {
    late AppLogger logger;
    late DispatchWebSocketClient client;

    setUp(() {
      logger = AppLogger();
      client = DispatchWebSocketClient(logger: logger);
    });

    tearDown(() {
      client.dispose();
    });

    test('connect transitions status to connecting then connected', () async {
      expect(client.status, equals(WebSocketConnectionStatus.disconnected));

      client.connect('/ws/rides/ride-123');
      expect(client.status, equals(WebSocketConnectionStatus.connecting));

      await Future.delayed(const Duration(milliseconds: 250));
      expect(client.status, equals(WebSocketConnectionStatus.connected));
    });

    test('handleDisconnect triggers reconnecting status with backoff', () async {
      client.connect('/ws/rides/ride-123');
      await Future.delayed(const Duration(milliseconds: 250));

      client.handleDisconnect('/ws/rides/ride-123');
      expect(client.status, equals(WebSocketConnectionStatus.reconnecting));
    });
  });
}
