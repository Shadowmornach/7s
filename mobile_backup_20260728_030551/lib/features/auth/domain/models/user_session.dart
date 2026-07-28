enum UserRole { passenger, rider, owner }

class UserSession {
  final String userId;
  final String phoneNumber;
  final UserRole role;
  final DateTime expiresAt;

  const UserSession({
    required this.userId,
    required this.phoneNumber,
    required this.role,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);

  /// Amendment 20 — Token Refresh Buffer (3 minutes)
  bool get shouldProactivelyRefresh =>
      expiresAt.difference(DateTime.now().toUtc()) < const Duration(minutes: 3);

  static UserRole parseRole(String roleStr) {
    switch (roleStr.toLowerCase()) {
      case 'rider':
      case 'driver':
        return UserRole.rider;
      case 'owner':
      case 'fleet_owner':
        return UserRole.owner;
      default:
        return UserRole.passenger;
    }
  }
}
