import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../auth/token_storage.dart';
import '../logging/app_logger.dart';
import 'api_exceptions.dart';
import 'dto/error_response_dto.dart';

class ApiClient {
  final http.Client _httpClient;
  final AppConfig _config;
  final TokenStorage _tokenStorage;
  final AppLogger _logger;

  ApiClient({
    http.Client? httpClient,
    required AppConfig config,
    required TokenStorage tokenStorage,
    required AppLogger logger,
  })  : _httpClient = httpClient ?? http.Client(),
        _config = config,
        _tokenStorage = tokenStorage,
        _logger = logger;

  Future<Map<String, String>> _buildHeaders({bool requiresAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-App-Version': _config.appVersion,
      'X-Platform': Platform.isAndroid ? 'android' : Platform.isIOS ? 'ios' : 'other',
      'X-Client-Version': '${_config.appVersion}+${_config.buildNumber}',
    };

    if (requiresAuth) {
      final token = await _tokenStorage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '${_config.baseUrl}$cleanPath';
    return Uri.parse(fullUrl).replace(queryParameters: queryParameters);
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
    bool requiresAuth = true,
    int maxRetries = 2,
    Duration? timeout,
  }) async {
    return _executeWithRetry(
      () => _performRequest('GET', path, queryParameters: queryParameters, requiresAuth: requiresAuth, timeout: timeout ?? _config.apiTimeout),
      isIdempotent: true,
      maxRetries: maxRetries,
    );
  }

  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    bool requiresAuth = true,
    Duration? timeout,
  }) async {
    return _executeWithRetry(
      () => _performRequest('POST', path, body: body, queryParameters: queryParameters, requiresAuth: requiresAuth, timeout: timeout ?? _config.apiTimeout),
      isIdempotent: false,
      maxRetries: 0,
    );
  }

  Future<dynamic> put(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    bool requiresAuth = true,
    Duration? timeout,
  }) async {
    return _executeWithRetry(
      () => _performRequest('PUT', path, body: body, queryParameters: queryParameters, requiresAuth: requiresAuth, timeout: timeout ?? _config.apiTimeout),
      isIdempotent: false,
      maxRetries: 0,
    );
  }

  Future<dynamic> delete(
    String path, {
    Map<String, String>? queryParameters,
    bool requiresAuth = true,
    Duration? timeout,
  }) async {
    return _executeWithRetry(
      () => _performRequest('DELETE', path, queryParameters: queryParameters, requiresAuth: requiresAuth, timeout: timeout ?? _config.apiTimeout),
      isIdempotent: false,
      maxRetries: 0,
    );
  }

  Future<dynamic> _performRequest(
    String method,
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    bool requiresAuth = true,
    required Duration timeout,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final headers = await _buildHeaders(requiresAuth: requiresAuth);
    final encodedBody = body != null ? jsonEncode(body) : null;

    _logger.info('HTTP $method -> ${uri.path}');

    http.Response response;
    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _httpClient.get(uri, headers: headers).timeout(timeout);
          break;
        case 'POST':
          response = await _httpClient.post(uri, headers: headers, body: encodedBody).timeout(timeout);
          break;
        case 'PUT':
          response = await _httpClient.put(uri, headers: headers, body: encodedBody).timeout(timeout);
          break;
        case 'DELETE':
          response = await _httpClient.delete(uri, headers: headers).timeout(timeout);
          break;
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }
    } on SocketException catch (e, st) {
      _logger.error('SocketException on $method $path', e, st);
      throw NetworkException(message: 'Network connection unavailable. Please check your internet connection.', originalError: e);
    } on TimeoutException catch (e, st) {
      _logger.error('TimeoutException on $method $path', e, st);
      throw NetworkException(message: 'Network request timed out. Please try again.', originalError: e);
    } on http.ClientException catch (e, st) {
      _logger.error('ClientException on $method $path', e, st);
      throw NetworkException(message: 'HTTP client failure', originalError: e);
    }

    return _parseResponse(response);
  }

  Future<dynamic> _executeWithRetry(
    Future<dynamic> Function() action, {
    required bool isIdempotent,
    required int maxRetries,
  }) async {
    int attempts = 0;
    while (true) {
      attempts++;
      try {
        return await action();
      } on NetworkException {
        // Refinement 2: Retries ONLY on transport NetworkException (Socket/Timeout) for idempotent GET requests.
        // Never retries HTTP 500/503 server responses (which raise BackendRejectedException).
        if (!isIdempotent || attempts > maxRetries) {
          rethrow;
        }
        // Refinement 2: Exponential backoff (300ms * 2^(attempts-1))
        final backoffMs = 300 * (1 << (attempts - 1));
        _logger.warning('Retrying idempotent request (Attempt $attempts of $maxRetries) after ${backoffMs}ms...');
        await Future.delayed(Duration(milliseconds: backoffMs));
      }
    }
  }

  dynamic _parseResponse(http.Response response) {
    final statusCode = response.statusCode;
    _logger.info('HTTP Response Status: $statusCode');

    dynamic decodedJson;
    try {
      if (response.body.isNotEmpty) {
        decodedJson = jsonDecode(response.body);
      }
    } catch (_) {
      decodedJson = null;
    }

    if (statusCode >= 200 && statusCode < 300) {
      return decodedJson;
    }

    if (statusCode == 401) {
      throw const UnauthorizedException('Authentication token missing or invalid');
    }

    // Refinement 2: Server errors (500/502/503/504) and 4xx rejections raise BackendRejectedException immediately.
    // They are NEVER automatically retried by the networking layer.
    if (decodedJson is Map<String, dynamic>) {
      final errorDto = ErrorResponseDto.fromJson(decodedJson);
      throw BackendRejectedException(
        errorCode: errorDto.errorCode,
        statusCode: statusCode,
        message: errorDto.message,
      );
    }

    throw BackendRejectedException(
      errorCode: 'HTTP_$statusCode',
      statusCode: statusCode,
      message: response.reasonPhrase ?? 'Server error with code $statusCode',
    );
  }
}
