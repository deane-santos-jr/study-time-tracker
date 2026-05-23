import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:study_time_tracker/src/domain/services/token_storage_service_intf.dart';

const String _refreshTokenKey = 'refresh_token';
const String _securePrefix = 'secure_';

/// Per ADR-0009 / ARCHITECTURE.md: the refresh token is durable and lives in
/// the platform secure store; the access token and its expiry are short-lived
/// and only held in memory, so a process restart forces a refresh via the
/// stored refresh token.
class TokenStorageService implements ITokenStorageService {
  TokenStorageService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;
  final ValueNotifier<bool> _isAuthenticated = ValueNotifier<bool>(false);

  String? _accessToken;
  DateTime? _expiresAt;

  @override
  ValueListenable<bool> get isAuthenticated => _isAuthenticated;

  @override
  Future<void> init() async {
    final refresh = await _secureStorage.read(key: _refreshTokenKey);
    _isAuthenticated.value = refresh != null && refresh.isNotEmpty;
  }

  @override
  Future<void> saveAccessToken(String token) async {
    _accessToken = token;
    if (!_isAuthenticated.value) _isAuthenticated.value = true;
  }

  @override
  Future<String?> getAccessToken() async => _accessToken;

  @override
  Future<bool> hasAccessToken() async =>
      _accessToken != null && _accessToken!.isNotEmpty;

  @override
  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: _refreshTokenKey, value: token);
    if (!_isAuthenticated.value) _isAuthenticated.value = true;
  }

  @override
  Future<String?> getRefreshToken() =>
      _secureStorage.read(key: _refreshTokenKey);

  @override
  Future<bool> hasRefreshToken() async {
    final token = await getRefreshToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> saveExpiresAt(DateTime expiresAt) async {
    _expiresAt = expiresAt;
  }

  @override
  Future<DateTime?> getExpiresAt() async => _expiresAt;

  @override
  Future<bool> isAccessTokenExpired({
    Duration buffer = const Duration(seconds: 30),
  }) async {
    if (_expiresAt == null) return true;
    return DateTime.now().isAfter(_expiresAt!.subtract(buffer));
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
  Future<void> clearAccessToken() async {
    _accessToken = null;
    _expiresAt = null;
  }

  @override
  Future<void> clearRefreshToken() async {
    await _secureStorage.delete(key: _refreshTokenKey);
    _isAuthenticated.value = false;
  }

  @override
  Future<void> clearSecureValue(String key) =>
      _secureStorage.delete(key: '$_securePrefix$key');

  @override
  Future<void> clearAll() async {
    _accessToken = null;
    _expiresAt = null;
    // Only delete keys this service owns — `deleteAll()` would also wipe
    // secrets persisted by other packages or features.
    await _secureStorage.delete(key: _refreshTokenKey);
    _isAuthenticated.value = false;
  }
}
