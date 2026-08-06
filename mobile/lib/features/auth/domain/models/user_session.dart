enum UserRole {
  passenger,
  rider,
  owner;

  static const customer = passenger;
  static const driver = rider;
  static const admin = owner;
}

class UserSession {
  final String uid;
  final String email;
  final String nickname;
  final String? fullName;
  final String? photoUrl;
  final String? phoneNumber;
  final String serviceZone;
  final String preferredPaymentMethod;
  final List<String> favoritePlaces;
  final String? homeLocation;
  final String? workLocation;
  final UserRole role;
  final bool isProfileComplete;
  final bool isActive;
  final String? emergencyContact;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastLogin;
  final DateTime expiresAt;

  const UserSession({
    required this.uid,
    required this.email,
    required this.nickname,
    this.fullName,
    this.photoUrl,
    this.phoneNumber,
    this.serviceZone = 'VOI',
    this.preferredPaymentMethod = 'Cash',
    this.favoritePlaces = const [],
    this.homeLocation,
    this.workLocation,
    this.role = UserRole.passenger,
    this.isProfileComplete = false,
    this.isActive = true,
    this.emergencyContact,
    required this.createdAt,
    required this.updatedAt,
    required this.lastLogin,
    required this.expiresAt,
  });

  /// Alias for backward compatibility
  String get userId => uid;

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);

  bool get shouldProactivelyRefresh =>
      expiresAt.difference(DateTime.now().toUtc()) < const Duration(minutes: 3);

  /// Computes display initials e.g. "John Doe" -> "JD" or "Shadow" -> "SH"
  String get initials {
    if (fullName != null && fullName!.trim().isNotEmpty) {
      final parts = fullName!.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    if (nickname.trim().isNotEmpty) {
      return nickname.trim().substring(0, nickname.trim().length >= 2 ? 2 : 1).toUpperCase();
    }
    if (email.contains('@')) {
      final prefix = email.split('@')[0];
      return prefix.substring(0, prefix.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '7S';
  }

  static UserRole parseRole(String roleStr) {
    switch (roleStr.toLowerCase()) {
      case 'rider':
      case 'driver':
        return UserRole.rider;
      case 'owner':
      case 'admin':
        return UserRole.owner;
      default:
        return UserRole.passenger;
    }
  }

  UserSession copyWith({
    String? uid,
    String? email,
    String? nickname,
    String? fullName,
    String? photoUrl,
    String? phoneNumber,
    String? serviceZone,
    String? preferredPaymentMethod,
    List<String>? favoritePlaces,
    String? homeLocation,
    String? workLocation,
    UserRole? role,
    bool? isProfileComplete,
    bool? isActive,
    String? emergencyContact,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLogin,
    DateTime? expiresAt,
  }) {
    return UserSession(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      fullName: fullName ?? this.fullName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      serviceZone: serviceZone ?? this.serviceZone,
      preferredPaymentMethod: preferredPaymentMethod ?? this.preferredPaymentMethod,
      favoritePlaces: favoritePlaces ?? this.favoritePlaces,
      homeLocation: homeLocation ?? this.homeLocation,
      workLocation: workLocation ?? this.workLocation,
      role: role ?? this.role,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      isActive: isActive ?? this.isActive,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLogin: lastLogin ?? this.lastLogin,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
