import 'dart:async';
import '../../../../core/logging/app_logger.dart';

enum WebSocketConnectionStatus { disconnected, connecting, connected, reconnecting }

class DispatchWebSocketClient {
  final AppLogger _logger;

  WebSocketConnectionStatus _status = WebSocketConnectionStatus.disconnected;
  int _reconnectAttempt = 0;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  final StreamController<Map<String, dynamic>> _messageController = StreamController.broadcast();

  DispatchWebSocketClient({required AppLogger logger}) : _logger = logger;

  WebSocketConnectionStatus get status => _status;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  void connect(String channel) {
    if (_status == WebSocketConnectionStatus.connected) return;

    _status = WebSocketConnectionStatus.connecting;
    _logger.info('Telemetry: [ws_connecting] Channel: $channel');

    // Simulate WebSocket Connection Success
    Future.delayed(const Duration(milliseconds: 200), () {
      _status = WebSocketConnectionStatus.connected;
      _reconnectAttempt = 0;
      _logger.info('Telemetry: [ws_connected] Channel: $channel');
      _startHeartbeat();
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_status == WebSocketConnectionStatus.connected) {
        _logger.info('Telemetry: [ws_heartbeat_sent]');
      }
    });
  }

  void handleDisconnect(String channel) {
    if (_status == WebSocketConnectionStatus.disconnected) return;

    _status = WebSocketConnectionStatus.reconnecting;
    _heartbeatTimer?.cancel();

    // OA-05 & Amendment 25: Exponential backoff (1s, 2s, 4s, 8s, max 30s)
    final delaySeconds = (1 << _reconnectAttempt).clamp(1, 30);
    _reconnectAttempt++;

    _logger.warning('Telemetry: [ws_reconnecting] Attempt: $_reconnectAttempt Delay: ${delaySeconds}s');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      connect(channel);
    });
  }

  void sendPayload(Map<String, dynamic> payload) {
    if (_status == WebSocketConnectionStatus.connected) {
      _logger.info('Telemetry: [ws_payload_sent]');
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _status = WebSocketConnectionStatus.disconnected;
    _logger.info('Telemetry: [ws_disconnected]');
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
