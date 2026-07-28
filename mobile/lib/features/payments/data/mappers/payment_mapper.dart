import '../dto/payment_method_dto.dart';
import '../dto/payment_receipt_dto.dart';
import '../../domain/models/payment_method.dart';
import '../../domain/models/payment_receipt.dart';

class PaymentMapper {
  static PaymentMethodItem methodFromDto(PaymentMethodDto dto) {
    return PaymentMethodItem(
      id: dto.id,
      name: dto.name,
      icon: dto.icon,
      isEnabled: dto.isEnabled,
    );
  }

  static PaymentReceipt receiptFromDto(PaymentReceiptDto dto) {
    return PaymentReceipt(
      receiptId: dto.receiptId,
      rideId: dto.rideId,
      baseFare: dto.baseFare,
      distanceFare: dto.distanceFare,
      surgeAmount: dto.surgeAmount,
      discountAmount: dto.discountAmount,
      totalFare: dto.totalFare,
      currency: dto.currency,
      paymentMethodName: dto.paymentMethodName,
      timestamp: DateTime.tryParse(dto.timestampIso) ?? DateTime.now().toUtc(),
    );
  }
}
