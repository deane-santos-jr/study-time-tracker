class StartSessionPayload {
  /// Subject-attached session.
  StartSessionPayload.forSubject({required String subjectId, String? semesterId})
      : subjectId = subjectId,
        semesterId = semesterId,
        activityName = null;

  /// Ad-hoc session (no subject, free-text activity).
  StartSessionPayload.adHoc({required String activityName})
      : subjectId = null,
        semesterId = null,
        activityName = activityName;

  final String? subjectId;
  final String? semesterId;
  final String? activityName;

  Map<String, dynamic> toJson() => {
        if (subjectId != null) 'subjectId': subjectId,
        if (semesterId != null) 'semesterId': semesterId,
        if (activityName != null) 'activityName': activityName,
      };
}
