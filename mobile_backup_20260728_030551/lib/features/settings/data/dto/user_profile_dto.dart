class UserProfileDto {
  final String userId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String avatarUrl;
  final bool isPhoneVerified;
  final bool isEmailVerified;

  const UserProfileDto({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.avatarUrl,
    required this.isPhoneVerified,
    required this.isEmailVerified,
  });

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    return UserProfileDto(
      userId: json['user_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
      isPhoneVerified: json['is_phone_verified'] as bool? ?? false,
      isEmailVerified: json['is_email_verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'is_phone_verified': isPhoneVerified,
      'is_email_verified': isEmailVerified,
    };
  }
}
