class SubjectCreatePayload {
  SubjectCreatePayload({
    required this.name,
    required this.color,
    required this.semesterId,
    this.icon,
  });

  final String name;
  final String color;
  final String semesterId;
  final String? icon;

  Map<String, dynamic> toJson() => {
        'name': name,
        'color': color,
        'semesterId': semesterId,
        if (icon != null) 'icon': icon,
      };
}

class SubjectUpdatePayload {
  SubjectUpdatePayload({this.name, this.color, this.icon});

  final String? name;
  final String? color;
  final String? icon;

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (color != null) 'color': color,
        if (icon != null) 'icon': icon,
      };
}
