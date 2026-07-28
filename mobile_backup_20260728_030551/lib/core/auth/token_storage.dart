import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_state.dart';

abstract class TokenStorage {
  Future<void> writeTokens(AuthTokens tokens);
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> clearTokens();
}

class SecureTokenStorage implements TokenStorage {
  static const String _accessTokenKey = '7s_jwt_access_token';
  static const String _refreshTokenKey = '7s_jwt_refresh_token';

  final FlutterSecureStorage _storage;

  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<void> writeTokens(AuthTokens tokens) async {
    await _storage.write(key: _accessTokenKey, value: tokens.accessToken);
    await _storage.write(key: _refreshTokenKey, value: tokens.refreshToken);
  }

  @override
  Future<String?> readAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  @override
  Future<String?> readRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  @override
  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
