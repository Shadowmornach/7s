import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/connectivity/connectivity_service.dart';
import 'package:mobile/core/logging/app_logger.dart';
import 'package:mobile/features/dispatch/data/websocket/dispatch_websocket_client.dart';
import 'package:mobile/features/payments/domain/models/payment_method.dart';
import 'package:mobile/features/payments/domain/models/payment_receipt.dart';
import 'package:mobile/features/payments/domain/models/payment_status_snapshot.dart';
import 'package:mobile/features/payments/domain/repositories/payment_repository.dart';
import 'package:mobile/features/payments/presentation/providers/payment_provider.dart';

class MockPaymentRepository implements PaymentRepository {
  int pollCount = 0;
  PaymentStatusSnapshot? statusToReturn;

  @override
  Future<List<PaymentMethodItem>> getPaymentMethods() async {
    return const [
      PaymentMethodItem(id: 'mpesa', name: 'M-Pesa STK', icon: 'phone', isEnabled: true),
    ];
  }

  @override
  Future<String> initiateStkPush({required String rideId, required String phoneNumber, required double amount}) async {
    return 'trx-mock-stk-123';
  }

  @override
  Future<PaymentReceipt> getReceipt(String receiptId) async {
    return PaymentReceipt(
      receiptId: receiptId,
      rideId: 'ride-1',
      baseFare: 100.0,
      distanceFare: 200.0,
      surgeAmount: 0.0,
      discountAmount: 0.0,
      totalFare: 300.0,
      currency: 'KES',
      paymentMethodName: 'M-Pesa',
      timestamp: DateTime.now().toUtc(),
    );
  }

  @override
  Future<PaymentStatusSnapshot> getPaymentStatus(String rideId) async {
    pollCount++;
    return statusToReturn ?? PaymentStatusSnapshot(
      rideId: rideId,
      paymentStatus: 'PENDING',
      isTerminal: false,
    );
  }
}

class MockDispatchWebSocketClient extends DispatchWebSocketClient {
  final StreamController<Map<String, dynamic>> _controller = StreamController.broadcast();
  bool connected = false;

  MockDispatchWebSocketClient() : super(logger: AppLogger());

  @override
  Stream<Map<String, dynamic>> get messageStream => _controller.stream;

  @override
  void connect(String channel) {
    connected = true;
  }

  void emitWsMessage(Map<String, dynamic> data) {
    _controller.add(data);
  }

  @override
  void disconnect() {
    connected = false;
  }

  void closeController() {
    _controller.close();
  }
}

class MockConnectivityService implements ConnectivityService {
  final StreamController<ConnectivityStatus> _controller = StreamController.broadcast();
  ConnectivityStatus _status = ConnectivityStatus.offline;

  @override
  Future<ConnectivityStatus> checkConnectivity() async => _status;

  @override
  Stream<ConnectivityStatus> get onConnectivityChanged => _controller.stream;

  @override
  bool get isBackendReachable => _status == ConnectivityStatus.online;

  void goOnline() {
    _status = ConnectivityStatus.online;
    _controller.add(_status);
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  group('PaymentNotifier Gate 2 Unit Tests', () {
    late MockPaymentRepository repo;
    late MockDispatchWebSocketClient wsClient;
    late MockConnectivityService connectivity;

    setUp(() {
      repo = MockPaymentRepository();
      wsClient = MockDispatchWebSocketClient();
      connectivity = MockConnectivityService();
    });

    tearDown(() {
      wsClient.closeController();
      connectivity.dispose();
    });

    test('initiateStkPush transitions to waitingForPin, succeeds via WS message without delay', () async {
      final notifier = PaymentNotifier(
        repository: repo,
        wsClient: wsClient,
        connectivityService: connectivity,
      );

      expect(notifier.stkStatus, equals(StkPaymentStatus.idle));

      final future = notifier.initiateStkPush(
        rideId: 'ride-1',
        phoneNumber: '+254712345678',
        amount: 300.0,
      );
      await future;

      expect(notifier.stkStatus, equals(StkPaymentStatus.waitingForPin));
      expect(notifier.transactionId, equals('trx-mock-stk-123'));

      // Emit real-time WS update from backend
      wsClient.emitWsMessage({
        'id': 'ride-1',
        'payment_status': 'SUCCESS',
        'is_terminal': true,
      });

      await Future<void>.delayed(Duration.zero);

      expect(notifier.stkStatus, equals(StkPaymentStatus.success));
      notifier.dispose();
    });

    test('fallback polling updates status and stops when is_terminal is true', () async {
      repo.statusToReturn = const PaymentStatusSnapshot(
        rideId: 'ride-2',
        paymentStatus: 'SUCCESS',
        paymentMethod: 'MPESA',
        isTerminal: true,
      );

      final notifier = PaymentNotifier(
        repository: repo,
        wsClient: wsClient,
        connectivityService: connectivity,
      );

      await notifier.initiateStkPush(
        rideId: 'ride-2',
        phoneNumber: '+254712345678',
        amount: 300.0,
      );

      // Trigger periodic poll
      await Future<void>.delayed(const Duration(milliseconds: 3100));

      expect(notifier.stkStatus, equals(StkPaymentStatus.success));
      expect(repo.pollCount, equals(1));

      // Wait another period: verify polling STOPPED because isTerminal == true
      await Future<void>.delayed(const Duration(milliseconds: 3100));
      expect(repo.pollCount, equals(1)); // Poll count did not increase!

      notifier.dispose();
    });

    test('reconnect triggers immediate status poll check', () async {
      repo.statusToReturn = const PaymentStatusSnapshot(
        rideId: 'ride-3',
        paymentStatus: 'FAILED',
        isTerminal: true,
      );

      final notifier = PaymentNotifier(
        repository: repo,
        wsClient: wsClient,
        connectivityService: connectivity,
      );

      await notifier.initiateStkPush(
        rideId: 'ride-3',
        phoneNumber: '+254712345678',
        amount: 300.0,
      );

      expect(repo.pollCount, equals(0));

      // Connectivity restored -> triggers _pollStatus immediately
      connectivity.goOnline();
      await Future<void>.delayed(Duration.zero);

      expect(notifier.stkStatus, equals(StkPaymentStatus.failed));
      expect(repo.pollCount, equals(1));

      notifier.dispose();
    });

    test('resetStkStatus cancels monitoring and cleans up resources', () async {
      final notifier = PaymentNotifier(
        repository: repo,
        wsClient: wsClient,
        connectivityService: connectivity,
      );

      await notifier.initiateStkPush(
        rideId: 'ride-4',
        phoneNumber: '+254712345678',
        amount: 300.0,
      );

      notifier.resetStkStatus();

      expect(notifier.stkStatus, equals(StkPaymentStatus.idle));
      expect(notifier.transactionId, isNull);

      // Emit WS message after reset: should be ignored
      wsClient.emitWsMessage({
        'id': 'ride-4',
        'payment_status': 'SUCCESS',
        'is_terminal': true,
      });
      await Future<void>.delayed(Duration.zero);

      expect(notifier.stkStatus, equals(StkPaymentStatus.idle));
    });

    test('loadReceipt fetches receipt domain model', () async {
      final notifier = PaymentNotifier(repository: repo);

      expect(notifier.currentReceipt, isNull);
      await notifier.loadReceipt('rcpt-100');

      expect(notifier.currentReceipt, isNotNull);
      expect(notifier.currentReceipt!.receiptId, equals('rcpt-100'));
      expect(notifier.currentReceipt!.totalFare, equals(300.0));

      notifier.dispose();
    });

    test('duplicate status update does not trigger extra notifyListeners calls', () async {
      final notifier = PaymentNotifier(
        repository: repo,
        wsClient: wsClient,
        connectivityService: connectivity,
      );

      await notifier.initiateStkPush(
        rideId: 'ride-dup',
        phoneNumber: '+254712345678',
        amount: 300.0,
      );

      int listenerNotificationCount = 0;
      notifier.addListener(() {
        listenerNotificationCount++;
      });

      // Emit duplicate PENDING update via WS while already in waitingForPin
      wsClient.emitWsMessage({
        'id': 'ride-dup',
        'payment_status': 'PENDING',
        'is_terminal': false,
      });
      await Future<void>.delayed(Duration.zero);

      // Status did not change (was waitingForPin, remains waitingForPin)
      expect(listenerNotificationCount, equals(0));

      // Emit SUCCESS
      wsClient.emitWsMessage({
        'id': 'ride-dup',
        'payment_status': 'SUCCESS',
        'is_terminal': true,
      });
      await Future<void>.delayed(Duration.zero);

      // Status changed -> listener notified exactly once!
      expect(listenerNotificationCount, equals(1));
      expect(notifier.stkStatus, equals(StkPaymentStatus.success));

      notifier.dispose();
    });
  });
}

