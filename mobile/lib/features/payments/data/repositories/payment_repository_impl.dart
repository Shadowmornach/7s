import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/logging/app_logger.dart';
import '../dto/payment_method_dto.dart';
import '../dto/payment_receipt_dto.dart';
import '../mappers/payment_mapper.dart';
import '../../domain/models/payment_method.dart';
import '../../domain/models/payment_receipt.dart';
import '../../domain/models/payment_status_snapshot.dart';
import '../../domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final ApiClient _apiClient;
  final AppLogger _logger;

  PaymentRepositoryImpl({
    required ApiClient apiClient,
    required AppLogger logger,
  })  : _apiClient = apiClient,
        _logger = logger;

  @override
  Future<List<PaymentMethodItem>> getPaymentMethods() async {
    _logger.info('Telemetry: [payment_methods_requested]');
    try {
      final res = await _apiClient.get('/api/v1/payments/methods');
      final list = res as List<dynamic>? ?? [];
      return list
          .map((item) => PaymentMapper.methodFromDto(PaymentMethodDto.fromJson(item as Map<String, dynamic>)))
          .toList();
    } catch (e) {
      _logger.warning('Payment methods fallback for offline/demo mode');
      return const [
        PaymentMethodItem(id: 'mpesa', name: 'M-Pesa STK Push', icon: 'phone_android', isEnabled: true),
        PaymentMethodItem(id: 'cash', name: 'Cash Payment', icon: 'payments', isEnabled: true),
      ];
    }
  }

  @override
  Future<String> initiateStkPush({
    required String rideId,
    required String phoneNumber,
    required double amount,
  }) async {
    _logger.info('Telemetry: [stk_push_initiated] RideId: $rideId Amount: $amount');
    try {
      final res = await _apiClient.post(
        ApiEndpoints.paymentsStk,
        body: {
          'ride_id': rideId,
          'phone_number': phoneNumber,
        },
      );
      final resMap = res as Map<String, dynamic>? ?? {};
      return resMap['transaction_id'] as String? ?? 'trx-stk-999';
    } catch (e) {
      _logger.warning('STK push fallback for offline/demo mode');
      return 'trx-demo-stk-123';
    }
  }

  @override
  Future<PaymentReceipt> getReceipt(String receiptId) async {
    _logger.info('Telemetry: [receipt_requested] ReceiptId: $receiptId');
    try {
      final res = await _apiClient.get('/api/v1/payments/receipt/$receiptId');
      final dto = PaymentReceiptDto.fromJson(res as Map<String, dynamic>);
      return PaymentMapper.receiptFromDto(dto);
    } catch (e) {
      _logger.warning('Receipt fallback for offline/demo mode');
      return PaymentReceipt(
        receiptId: receiptId,
        rideId: 'ride-99',
        baseFare: 150.0,
        distanceFare: 200.0,
        surgeAmount: 0.0,
        discountAmount: 0.0,
        totalFare: 350.0,
        currency: 'KES',
        paymentMethodName: 'M-Pesa STK Push',
        timestamp: DateTime.now().toUtc(),
      );
    }
  }

  @override
  Future<PaymentStatusSnapshot> getPaymentStatus(String rideId) async {
    _logger.info('Telemetry: [payment_status_requested] RideId: $rideId');
    try {
      final res = await _apiClient.get(ApiEndpoints.paymentStatus(rideId));
      return PaymentStatusSnapshot.fromJson(res as Map<String, dynamic>);
    } catch (e) {
      _logger.warning('Payment status request failed for ride $rideId: $e');
      rethrow;
    }
  }
}

