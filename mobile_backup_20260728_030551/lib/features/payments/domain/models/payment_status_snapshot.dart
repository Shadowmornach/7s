class PaymentStatusSnapshot {
  final String rideId;
  final String paymentStatus;
  final String? paymentMethod;
  final String? updatedAt;
  final bool isTerminal;

  const PaymentStatusSnapshot({
    required this.rideId,
    required this.paymentStatus,
    this.paymentMethod,
    this.updatedAt,
    required this.isTerminal,
  });

  factory PaymentStatusSnapshot.fromJson(Map<String, dynamic> json) {
    return PaymentStatusSnapshot(
      rideId: json['ride_id'] as String,
      paymentStatus: json['payment_status'] as String,
      paymentMethod: json['payment_method'] as String?,
      updatedAt: json['updated_at'] as String?,
      isTerminal: json['is_terminal'] as bool? ?? false,
    );
  }
}
