import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:study_time_tracker/src/domain/services/token_storage_service_intf.dart';

const String _accessTokenKey = 'access_token';
const String _refreshTokenKey = 'refresh_token';
const String _expiresAtKey = 'expires_at';

class TokenStorageService implements ITokenStorageService {
  TokenStorageService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _securePrefix = 'secure_';
  final FlutterSecureStorage _secureStorage;

  @override
  Future<void> saveAccessToken(String token) =>
      _secureStorage.write(key: _accessTokenKey, value: token);

  @override
  Future<String?> getAccessToken() => _secureStorage.read(key: _accessTokenKey);

  @override
  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> saveRefreshToken(String token) =>
      _secureStorage.write(key: _refreshTokenKey, value: token);

  @override
  Future<String?> getRefreshToken() => _secureStorage.read(key: _refreshTokenKey);

  @override
  Future<bool> hasRefreshToken() async {
    final token = await getRefreshToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> saveExpiresAt(DateTime expiresAt) => _secureStorage.write(
        key: _expiresAtKey,
        value: expiresAt.toIso8601String(),
      );

  @override
  Future<DateTime?> getExpiresAt() async {
    final value = await _secureStorage.read(key: _expiresAtKey);
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  @override
  Future<bool> isAccessTokenExpired({
    Duration buffer = const Duration(seconds: 30),
  }) async {
    final expiresAt = await getExpiresAt();
    if (expiresAt == null) return true;
    return DateTime.now().isAfter(expiresAt.subtract(buffer));
  }

  @override
  Future<void> saveSecureValue(String key, String value) =>
      _secureStorage.write(key: '$_securePrefix$key', value: value);

  @override
  Future<String?> getSecureValue(String key) =>
      _secureStorage.read(key: '$_securePrefix$key');

  @override
  Future<bool> hasSecureValue(String key) async {
    final value = await getSecureValue(key);
    return value != null && value.isNotEmpty;
  }

  @override
  Future<void> clearAccessToken() => _secureStorage.delete(key: _accessTokenKey);

  @override
  Future<void> clearRefreshToken() =>
      _secureStorage.delete(key: _refreshTokenKey);

  @override
  Future<void> clearSecureValue(String key) =>
      _secureStorage.delete(key: '$_securePrefix$key');

  @override
  Future<void> clearAll() => _secureStorage.deleteAll();
}
