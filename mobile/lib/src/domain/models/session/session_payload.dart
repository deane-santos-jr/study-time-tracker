class StartSessionPayload {
  /// Subject-attached session.
  StartSessionPayload.forSubject({required this.subjectId, this.semesterId})
      : activityName = null;

  /// Ad-hoc session (no subject, free-text activity).
  StartSessionPayload.adHoc({required this.activityName})
      : subjectId = null,
        semesterId = null;

  final String? subjectId;
  final String? semesterId;
  final String? activityName;

  Map<String, dynamic> toJson() => {
        if (subjectId != null) 'subjectId': subjectId,
        if (semesterId != null) 'semesterId': semesterId,
        if (activityName != null) 'activityName': activityName,
      };
}
