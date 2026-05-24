class UserProfile {
  UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.createdAt,
    this.isActive = true,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        email: json['email'] as String,
        firstName: (json['firstName'] as String?) ?? '',
        lastName: (json['lastName'] as String?) ?? '',
        isActive: (json['isActive'] as bool?) ?? true,
        createdAt: _parseDate(json['createdAt']),
      );

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final bool isActive;
  final DateTime createdAt;

  String get fullName {
    final f = firstName.trim();
    final l = lastName.trim();
    if (f.isEmpty && l.isEmpty) return email;
    if (f.isEmpty) return l;
    if (l.isEmpty) return f;
    return '$f $l';
  }

  static DateTime _parseDate(Object? value) {
    if (value is String) return DateTime.parse(value).toLocal();
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value).toLocal();
    }
    return DateTime.now();
  }
}
