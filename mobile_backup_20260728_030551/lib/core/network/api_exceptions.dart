abstract class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

class BackendRejectedException extends ApiException {
  final String errorCode;
  final int statusCode;

  const BackendRejectedException({
    required this.errorCode,
    required this.statusCode,
    required String message,
  }) : super(message);

  @override
  String toString() => 'BackendRejectedException [$statusCode: $errorCode]: $message';
}

class NetworkException extends ApiException {
  final Object? originalError;

  const NetworkException({
    required String message,
    this.originalError,
  }) : super(message);

  @override
  String toString() => 'NetworkException: $message';
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Session expired or unauthenticated']);
}
