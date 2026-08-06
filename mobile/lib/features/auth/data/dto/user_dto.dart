class UserDto {
  final String id;
  final String email;
  final String? phoneNumber;
  final String? nickname;
  final String? fullName;
  final String? photoUrl;
  final String role;
  final bool isProfileComplete;

  const UserDto({
    required this.id,
    required this.email,
    this.phoneNumber,
    this.nickname,
    this.fullName,
    this.photoUrl,
    required this.role,
    this.isProfileComplete = false,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phone_number'] as String?,
      nickname: json['nickname'] as String?,
      fullName: json['full_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      role: json['role'] as String? ?? 'PASSENGER',
      isProfileComplete: json['is_profile_complete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone_number': phoneNumber,
      'nickname': nickname,
      'full_name': fullName,
      'photo_url': photoUrl,
      'role': role,
      'is_profile_complete': isProfileComplete,
    };
  }
}
