class AuthToken {
  AuthToken({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    final accessToken = (json['token'] ?? json['accessToken']) as String;
    final refreshToken = json['refreshToken'] as String;
    final expiresAtRaw = json['expiresAt'];
    final DateTime expiresAt;
    if (expiresAtRaw is String) {
      expiresAt = DateTime.parse(expiresAtRaw).toLocal();
    } else if (expiresAtRaw is int) {
      expiresAt = DateTime.fromMillisecondsSinceEpoch(expiresAtRaw).toLocal();
    } else {
      expiresAt = DateTime.now().add(const Duration(minutes: 15));
    }
    return AuthToken(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
  }

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
}
