class PaymentReceiptDto {
  final String receiptId;
  final String rideId;
  final double baseFare;
  final double distanceFare;
  final double surgeAmount;
  final double discountAmount;
  final double totalFare;
  final String currency;
  final String paymentMethodName;
  final String timestampIso;

  const PaymentReceiptDto({
    required this.receiptId,
    required this.rideId,
    required this.baseFare,
    required this.distanceFare,
    required this.surgeAmount,
    required this.discountAmount,
    required this.totalFare,
    required this.currency,
    required this.paymentMethodName,
    required this.timestampIso,
  });

  factory PaymentReceiptDto.fromJson(Map<String, dynamic> json) {
    return PaymentReceiptDto(
      receiptId: json['receipt_id'] as String? ?? '',
      rideId: json['ride_id'] as String? ?? '',
      baseFare: (json['base_fare'] as num?)?.toDouble() ?? 0.0,
      distanceFare: (json['distance_fare'] as num?)?.toDouble() ?? 0.0,
      surgeAmount: (json['surge_amount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      totalFare: (json['total_fare'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'KES',
      paymentMethodName: json['payment_method_name'] as String? ?? 'Cash',
      timestampIso: json['timestamp_iso'] as String? ?? '',
    );
  }
}
