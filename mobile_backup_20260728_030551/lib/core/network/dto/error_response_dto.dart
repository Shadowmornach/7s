class ErrorResponseDto {
  final String errorCode;
  final String message;

  const ErrorResponseDto({
    required this.errorCode,
    required this.message,
  });

  factory ErrorResponseDto.fromJson(Map<String, dynamic> json) {
    return ErrorResponseDto(
      errorCode: json['error_code'] as String? ?? 'UNKNOWN_ERROR',
      message: json['message'] as String? ?? 'An unexpected backend error occurred',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error_code': errorCode,
      'message': message,
    };
  }
}
