import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/payments/data/dto/payment_method_dto.dart';
import 'package:mobile/features/payments/data/dto/payment_receipt_dto.dart';
import 'package:mobile/features/payments/data/mappers/payment_mapper.dart';

void main() {
  group('PaymentMapper Unit Tests', () {
    test('methodFromDto maps PaymentMethodDto to PaymentMethodItem domain model', () {
      const dto = PaymentMethodDto(
        id: 'mpesa',
        name: 'M-Pesa STK Push',
        icon: 'phone_android',
        isEnabled: true,
      );

      final item = PaymentMapper.methodFromDto(dto);

      expect(item.id, equals('mpesa'));
      expect(item.name, equals('M-Pesa STK Push'));
      expect(item.isEnabled, isTrue);
    });

    test('receiptFromDto maps PaymentReceiptDto to PaymentReceipt domain model', () {
      const dto = PaymentReceiptDto(
        receiptId: 'rcpt-1',
        rideId: 'ride-99',
        baseFare: 150.0,
        distanceFare: 200.0,
        surgeAmount: 0.0,
        discountAmount: 0.0,
        totalFare: 350.0,
        currency: 'KES',
        paymentMethodName: 'M-Pesa STK Push',
        timestampIso: '2026-07-26T12:00:00Z',
      );

      final receipt = PaymentMapper.receiptFromDto(dto);

      expect(receipt.receiptId, equals('rcpt-1'));
      expect(receipt.formattedTotal, equals('KES 350'));
      expect(receipt.formattedBase, equals('KES 150'));
    });
  });
}
