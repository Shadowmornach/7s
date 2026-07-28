import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class AppLogger {
  static final RegExp _secretRegExp = RegExp(
    r'(bearer\s+[a-zA-Z0-9\._\-]+|ey[a-zA-Z0-9\._\-]+|password|secret|token|authorization)',
    caseSensitive: false,
  );

  void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (kReleaseMode) return; // Refinement 5: No-op in release builds
    _log(LogLevel.debug, message, error, stackTrace);
  }

  void info(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }

  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  void severe(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  void _log(LogLevel level, String message, Object? error, StackTrace? stackTrace) {
    final sanitizedMessage = _sanitize(message);
    final sanitizedError = error != null ? _sanitize(error.toString()) : null;

    developer.log(
      '[${level.name.toUpperCase()}] $sanitizedMessage',
      error: sanitizedError,
      stackTrace: stackTrace,
      name: '7s.mobile',
    );
  }

  String _sanitize(String input) {
    if (input.isEmpty) return input;
    return input.replaceAllMapped(_secretRegExp, (match) => '[REDACTED_SECRET]');
  }
}
