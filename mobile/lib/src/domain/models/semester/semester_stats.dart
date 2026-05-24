class SemesterStats {
  const SemesterStats({
    required this.subjectCount,
    required this.sessionCount,
    required this.totalSeconds,
  });

  factory SemesterStats.fromJson(Map<String, dynamic> json) => SemesterStats(
        subjectCount: (json['subjectCount'] as num?)?.toInt() ?? 0,
        sessionCount: (json['sessionCount'] as num?)?.toInt() ?? 0,
        totalSeconds: (json['totalSeconds'] as num?)?.toInt() ?? 0,
      );

  final int subjectCount;
  final int sessionCount;
  final int totalSeconds;
}
