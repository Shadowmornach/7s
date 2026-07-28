import '../models/payment_method.dart';
import '../models/payment_receipt.dart';
import '../models/payment_status_snapshot.dart';

abstract class PaymentRepository {
  Future<List<PaymentMethodItem>> getPaymentMethods();

  Future<String> initiateStkPush({
    required String rideId,
    required String phoneNumber,
    required double amount,
  });

  Future<PaymentReceipt> getReceipt(String receiptId);

  Future<PaymentStatusSnapshot> getPaymentStatus(String rideId);
}
