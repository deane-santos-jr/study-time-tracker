abstract class ITokenStorageService {
  Future<void> saveAccessToken(String token);
  Future<String?> getAccessToken();
  Future<bool> hasAccessToken();

  Future<void> saveRefreshToken(String token);
  Future<String?> getRefreshToken();
  Future<bool> hasRefreshToken();

  Future<void> saveExpiresAt(DateTime expiresAt);
  Future<DateTime?> getExpiresAt();
  Future<bool> isAccessTokenExpired({Duration buffer = const Duration(seconds: 30)});

  Future<void> saveSecureValue(String key, String value);
  Future<String?> getSecureValue(String key);
  Future<bool> hasSecureValue(String key);

  Future<void> clearAccessToken();
  Future<void> clearRefreshToken();
  Future<void> clearSecureValue(String key);
  Future<void> clearAll();
}
