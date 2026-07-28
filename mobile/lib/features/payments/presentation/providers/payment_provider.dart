import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/connectivity/connectivity_service.dart';
import '../../../dispatch/data/websocket/dispatch_websocket_client.dart';
import '../../domain/models/payment_method.dart';
import '../../domain/models/payment_receipt.dart';
import '../../domain/models/payment_status_snapshot.dart';
import '../../domain/repositories/payment_repository.dart';

enum StkPaymentStatus { idle, sendingPrompt, waitingForPin, success, failed }

class PaymentNotifier extends ChangeNotifier {
  final PaymentRepository _repository;
  final DispatchWebSocketClient? _wsClient;
  final ConnectivityService? _connectivityService;

  StkPaymentStatus _stkStatus = StkPaymentStatus.idle;
  String? _transactionId;
  PaymentReceipt? _currentReceipt;
  PaymentStatusSnapshot? _latestStatusSnapshot;
  final List<PaymentMethodItem> _methods = [];
  bool _isLoading = false;

  StreamSubscription<Map<String, dynamic>>? _wsSub;
  StreamSubscription<ConnectivityStatus>? _connSub;
  Timer? _pollTimer;
  String? _monitoredRideId;

  PaymentNotifier({
    required PaymentRepository repository,
    DispatchWebSocketClient? wsClient,
    ConnectivityService? connectivityService,
  })  : _repository = repository,
        _wsClient = wsClient,
        _connectivityService = connectivityService;

  StkPaymentStatus get stkStatus => _stkStatus;
  String? get transactionId => _transactionId;
  PaymentReceipt? get currentReceipt => _currentReceipt;
  PaymentStatusSnapshot? get latestStatusSnapshot => _latestStatusSnapshot;
  List<PaymentMethodItem> get methods => _methods;
  bool get isLoading => _isLoading;

  void resetStkStatus() {
    _cancelMonitoring();
    _stkStatus = StkPaymentStatus.idle;
    _transactionId = null;
    _latestStatusSnapshot = null;
    notifyListeners();
  }

  Future<void> initiateStkPush({
    required String rideId,
    required String phoneNumber,
    required double amount,
  }) async {
    _cancelMonitoring();
    _stkStatus = StkPaymentStatus.sendingPrompt;
    notifyListeners();

    try {
      _transactionId = await _repository.initiateStkPush(
        rideId: rideId,
        phoneNumber: phoneNumber,
        amount: amount,
      );
      _stkStatus = StkPaymentStatus.waitingForPin;
      _monitoredRideId = rideId;
      notifyListeners();

      _startMonitoring(rideId);
    } catch (e) {
      _stkStatus = StkPaymentStatus.failed;
      notifyListeners();
    }
  }

  void _startMonitoring(String rideId) {
    // 1. Primary mechanism: Listen to WebSocket real-time event stream
    if (_wsClient != null) {
      _wsClient.connect('ride_$rideId');
      _wsSub = _wsClient.messageStream.listen((data) {
        final messageRideId = data['id']?.toString() ?? data['ride_id']?.toString();
        if (messageRideId == rideId && data.containsKey('payment_status')) {
          _handlePaymentStatusUpdate(
            status: data['payment_status'] as String,
            isTerminal: data['is_terminal'] as bool? ??
                (data['payment_status'] == 'SUCCESS' ||
                 data['payment_status'] == 'FAILED' ||
                 data['payment_status'] == 'DISPUTED' ||
                 data['payment_status'] == 'REFUND_RECORDED'),
          );
        }
      });
    }

    // 2. Connectivity listener: on reconnect, poll immediately
    if (_connectivityService != null) {
      _connSub = _connectivityService.onConnectivityChanged.listen((connStatus) {
        if (connStatus == ConnectivityStatus.online && _monitoredRideId == rideId) {
          _pollStatus(rideId);
        }
      });
    }

    // 3. Fallback polling mechanism: poll GET /api/v1/payments/{ride_id}/status
    // Periodically polls if WS disconnects or as a backup safety check
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollStatus(rideId);
    });
  }

  Future<void> _pollStatus(String rideId) async {
    if (_monitoredRideId != rideId) return;

    try {
      final snapshot = await _repository.getPaymentStatus(rideId);
      _latestStatusSnapshot = snapshot;

      _handlePaymentStatusUpdate(
        status: snapshot.paymentStatus,
        isTerminal: snapshot.isTerminal,
      );
    } catch (e) {
      // Offline or network error during polling; continue monitoring unless cancelled
    }
  }

  void _handlePaymentStatusUpdate({required String status, required bool isTerminal}) {
    StkPaymentStatus newStkStatus = _stkStatus;
    if (status == 'SUCCESS') {
      newStkStatus = StkPaymentStatus.success;
    } else if (status == 'FAILED' || status == 'DISPUTED') {
      newStkStatus = StkPaymentStatus.failed;
    } else if (status == 'PENDING') {
      newStkStatus = StkPaymentStatus.waitingForPin;
    }

    final bool statusChanged = newStkStatus != _stkStatus;
    _stkStatus = newStkStatus;

    if (statusChanged) {
      notifyListeners();
    }

    // Backend is authority on is_terminal: stop polling and WS monitoring immediately
    if (isTerminal) {
      _cancelMonitoring();
    }
  }

  void _cancelMonitoring() {
    _pollTimer?.cancel();
    _pollTimer = null;

    _wsSub?.cancel();
    _wsSub = null;

    _connSub?.cancel();
    _connSub = null;

    _monitoredRideId = null;
  }

  Future<void> loadReceipt(String receiptId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentReceipt = await _repository.getReceipt(receiptId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _cancelMonitoring();
    super.dispose();
  }
}
