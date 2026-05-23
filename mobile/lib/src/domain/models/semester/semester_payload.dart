class SemesterCreatePayload {
  SemesterCreatePayload({
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  final String name;
  final DateTime startDate;
  final DateTime endDate;

  // Semester start/end are calendar dates, not instants. MySQL stores them in a
  // DATE column and a UTC conversion would shift the day for +0800 users.
  Map<String, dynamic> toJson() => {
        'name': name,
        'startDate': _formatDate(startDate),
        'endDate': _formatDate(endDate),
      };

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
