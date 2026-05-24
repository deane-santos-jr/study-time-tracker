enum SessionStatus { active, paused, completed }

class StudySession {
  StudySession({
    required this.id,
    required this.subjectId,
    required this.activityName,
    required this.startTime,
    required this.status,
    required this.accumulatedPauseTime,
    required this.breakCount,
    this.endTime,
    this.pausedAt,
    this.totalDuration,
    this.effectiveStudyTime,
  }) : assert(
          (subjectId == null) != (activityName == null),
          'StudySession must have exactly one of subjectId or activityName',
        );

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
        id: json['id'] as String,
        subjectId: json['subjectId'] as String?,
        activityName: json['activityName'] as String?,
        startTime: DateTime.parse(json['startTime'] as String).toLocal(),
        endTime: json['endTime'] == null
            ? null
            : DateTime.parse(json['endTime'] as String).toLocal(),
        pausedAt: json['pausedAt'] == null
            ? null
            : DateTime.parse(json['pausedAt'] as String).toLocal(),
        status: _parseStatus(json['status']),
        accumulatedPauseTime: (json['accumulatedPauseTime'] as num?)?.toInt() ?? 0,
        breakCount: (json['breakCount'] as num?)?.toInt() ?? 0,
        totalDuration: (json['totalDuration'] as num?)?.toInt(),
        effectiveStudyTime: (json['effectiveStudyTime'] as num?)?.toInt(),
      );

  final String id;
  final String? subjectId;
  final String? activityName;
  final DateTime startTime;
  final DateTime? endTime;
  final DateTime? pausedAt;
  final SessionStatus status;
  final int accumulatedPauseTime; // seconds
  final int breakCount;
  final int? totalDuration; // seconds
  final int? effectiveStudyTime; // seconds

  /// True when this session has no subject — its label is `activityName` and
  /// it aggregates into the dashboard's "other" totals row.
  bool get isAdHoc => subjectId == null;

  /// What the UI shows in the chip slot / history row in place of a subject
  /// name. For subject sessions, the caller resolves the subject and renders
  /// its name; for ad-hoc, this is the typed activity name.
  String get adHocLabel => activityName ?? '';

  /// Wall-clock derived effective elapsed (seconds) — never persisted as a
  /// counter (ADR-0003). When active, ticks against `now`; when paused, frozen
  /// at the moment of pause; when completed, equal to `effectiveStudyTime`.
  int effectiveElapsedAt(DateTime now) {
    final reference = switch (status) {
      SessionStatus.active => now,
      SessionStatus.paused => pausedAt ?? now,
      SessionStatus.completed => endTime ?? now,
    };
    final wallClock =
        reference.difference(startTime).inSeconds - accumulatedPauseTime;
    return wallClock < 0 ? 0 : wallClock;
  }

  static SessionStatus _parseStatus(dynamic raw) {
    final value = (raw as String?)?.toUpperCase();
    return switch (value) {
      'ACTIVE' => SessionStatus.active,
      'PAUSED' => SessionStatus.paused,
      'COMPLETED' => SessionStatus.completed,
      _ => SessionStatus.completed,
    };
  }
}
