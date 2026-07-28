class UserDto {
  final String id;
  final String phoneNumber;
  final String role;

  const UserDto({
    required this.id,
    required this.phoneNumber,
    required this.role,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      role: json['role'] as String? ?? 'passenger',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'role': role,
    };
  }
}
