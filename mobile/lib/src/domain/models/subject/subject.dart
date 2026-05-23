class Subject {
  Subject({
    required this.id,
    required this.semesterId,
    required this.name,
    required this.color,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.icon,
  });

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id'] as String,
        semesterId: json['semesterId'] as String,
        name: json['name'] as String,
        color: json['color'] as String,
        icon: json['icon'] as String?,
        isActive: json['isActive'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
        updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
      );

  final String id;
  final String semesterId;
  final String name;
  final String color;
  final String? icon;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}
