class PaymentMethodDto {
  final String id;
  final String name;
  final String icon;
  final bool isEnabled;

  const PaymentMethodDto({
    required this.id,
    required this.name,
    required this.icon,
    required this.isEnabled,
  });

  factory PaymentMethodDto.fromJson(Map<String, dynamic> json) {
    return PaymentMethodDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      isEnabled: json['is_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'is_enabled': isEnabled,
    };
  }
}
