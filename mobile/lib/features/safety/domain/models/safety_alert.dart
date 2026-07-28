enum SafetyAlertType { sos, silent, panic, incident }

class SafetyAlert {
  final String alertId;
  final String rideId;
  final SafetyAlertType type;
  final String status;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  const SafetyAlert({
    required this.alertId,
    required this.rideId,
    required this.type,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  static SafetyAlertType parseType(String str) {
    switch (str.toLowerCase()) {
      case 'silent':
        return SafetyAlertType.silent;
      case 'panic':
        return SafetyAlertType.panic;
      case 'incident':
        return SafetyAlertType.incident;
      default:
        return SafetyAlertType.sos;
    }
  }
}
