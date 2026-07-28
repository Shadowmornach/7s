class UserProfile {
  final String userId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String avatarUrl;
  final bool isPhoneVerified;
  final bool isEmailVerified;

  const UserProfile({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.avatarUrl,
    required this.isPhoneVerified,
    required this.isEmailVerified,
  });
}
