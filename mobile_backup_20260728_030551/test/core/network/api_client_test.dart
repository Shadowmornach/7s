import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/auth/token_storage.dart';
import 'package:mobile/core/auth/auth_state.dart';
import 'package:mobile/core/logging/app_logger.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/network/api_exceptions.dart';

class MemoryTokenStorage implements TokenStorage {
  AuthTokens? _tokens;

  @override
  Future<void> writeTokens(AuthTokens tokens) async => _tokens = tokens;

  @override
  Future<String?> readAccessToken() async => _tokens?.accessToken;

  @override
  Future<String?> readRefreshToken() async => _tokens?.refreshToken;

  @override
  Future<void> clearTokens() async => _tokens = null;
}

void main() {
  group('ApiClient Stage F0 Verification Tests', () {
    late AppConfig config;
    late MemoryTokenStorage tokenStorage;
    late AppLogger logger;

    setUp(() {
      config = const AppConfig(
        environment: AppEnvironment.development,
        baseUrl: 'http://127.0.0.1:8000',
        appVersion: '1.0.0',
        buildNumber: '1',
      );
      tokenStorage = MemoryTokenStorage();
      logger = AppLogger();
    });

    test('ApiClient correctly maps 4xx backend rejection response to BackendRejectedException', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"error_code": "PASSENGER_SUSPENDED", "message": "Passenger account has been suspended"}',
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        config: config,
        tokenStorage: tokenStorage,
        logger: logger,
      );

      await expectLater(
        () => apiClient.get('/api/v1/rides/test'),
        throwsA(
          isA<BackendRejectedException>()
              .having((e) => e.errorCode, 'errorCode', 'PASSENGER_SUSPENDED')
              .having((e) => e.statusCode, 'statusCode', 403)
              .having((e) => e.message, 'message', 'Passenger account has been suspended'),
        ),
      );
    });

    test('ApiClient correctly maps SocketException to NetworkException', () async {
      final mockClient = MockClient((request) async {
        throw const SocketException('Failed host lookup');
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        config: config,
        tokenStorage: tokenStorage,
        logger: logger,
      );

      await expectLater(
        () => apiClient.get('/api/v1/rides/test', maxRetries: 0),
        throwsA(
          isA<NetworkException>()
              .having((e) => e.message, 'message', contains('Network connection unavailable')),
        ),
      );
    });

    test('ApiClient attaches Authorization and dynamic client metadata headers to requests', () async {
      await tokenStorage.writeTokens(const AuthTokens(
        accessToken: 'test-jwt-token-xyz',
        refreshToken: 'test-refresh-token-123',
      ));

      late http.Request capturedRequest;
      final mockClient = MockClient((request) async {
        capturedRequest = request;
        return http.Response('{"status": "ok"}', 200, headers: {'content-type': 'application/json'});
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        config: config,
        tokenStorage: tokenStorage,
        logger: logger,
      );

      final res = await apiClient.get('/api/v1/health');

      expect(res, equals({'status': 'ok'}));
      expect(capturedRequest.headers['Authorization'], equals('Bearer test-jwt-token-xyz'));
      expect(capturedRequest.headers['X-App-Version'], equals('1.0.0'));
      expect(capturedRequest.headers['X-Platform'], isNotEmpty);
      expect(capturedRequest.headers['X-Client-Version'], equals('1.0.0+1'));
    });

    test('ApiClient enforces GET-only retries and does NOT automatically retry POST requests', () async {
      int postAttempts = 0;
      final mockClient = MockClient((request) async {
        if (request.method == 'POST') {
          postAttempts++;
          throw const SocketException('Connection dropped during POST');
        }
        return http.Response('{}', 200);
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        config: config,
        tokenStorage: tokenStorage,
        logger: logger,
      );

      await expectLater(
        () => apiClient.post('/api/v1/bookings', body: {'ride_id': '123'}),
        throwsA(isA<NetworkException>()),
      );
      expect(postAttempts, equals(1));
    });

    test('ApiClient does NOT automatically retry HTTP 500 server error responses', () async {
      int getAttempts = 0;
      final mockClient = MockClient((request) async {
        getAttempts++;
        return http.Response('{"error_code": "INTERNAL_ERROR", "message": "Server error"}', 500);
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        config: config,
        tokenStorage: tokenStorage,
        logger: logger,
      );

      await expectLater(
        () => apiClient.get('/api/v1/rides/500-test', maxRetries: 3),
        throwsA(isA<BackendRejectedException>()),
      );
      // HTTP 500 must return immediately without automatic retries
      expect(getAttempts, equals(1));
    });
  });
}
