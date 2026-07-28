class PaymentReceipt {
  final String receiptId;
  final String rideId;
  final double baseFare;
  final double distanceFare;
  final double surgeAmount;
  final double discountAmount;
  final double totalFare;
  final String currency;
  final String paymentMethodName;
  final DateTime timestamp;

  const PaymentReceipt({
    required this.receiptId,
    required this.rideId,
    required this.baseFare,
    required this.distanceFare,
    required this.surgeAmount,
    required this.discountAmount,
    required this.totalFare,
    required this.currency,
    required this.paymentMethodName,
    required this.timestamp,
  });

  String get formattedTotal => '$currency ${totalFare.toStringAsFixed(0)}';
  String get formattedBase => '$currency ${baseFare.toStringAsFixed(0)}';
  String get formattedDistance => '$currency ${distanceFare.toStringAsFixed(0)}';
}
