class Semester {
  Semester({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  factory Semester.fromJson(Map<String, dynamic> json) => Semester(
        id: json['id'] as String,
        name: json['name'] as String,
        startDate: DateTime.parse(json['startDate'] as String).toLocal(),
        endDate: DateTime.parse(json['endDate'] as String).toLocal(),
        isActive: json['isActive'] as bool? ?? false,
      );

  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
}
