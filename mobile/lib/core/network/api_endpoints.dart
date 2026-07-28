class ApiEndpoints {
  // System Health
  static const String health = '/health';

  // Auth (Argon2id + JWT)
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authOtpRequest = '/auth/otp/request';
  static const String refreshToken = '/auth/refresh';

  // Passenger & Rides
  static const String ridesQuote = '/api/v1/fare-templates/quote';
  static const String rides = '/rides';
  static const String places = '/api/v1/places/';
  static const String placesAutocomplete = '/api/v1/places/autocomplete';
  static const String driverOnline = '/driver/online';

  // Telemetry (assigned rider posts location updates during active ride)
  static const String telemetryLocation = '/rides'; // used as POST /rides/{id}/location dynamically

  // Payments (Daraja M-Pesa)
  static const String paymentsStk = '/api/v1/payments/stk-push';
  static const String paymentsCashConfirm = '/api/v1/payments/cash-confirm';
  static const String paymentsDispute = '/api/v1/payments/dispute';
  static String paymentStatus(String rideId) => '/api/v1/payments/$rideId/status';
}
