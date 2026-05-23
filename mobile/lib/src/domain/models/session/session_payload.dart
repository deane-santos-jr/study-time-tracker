class StartSessionPayload {
  StartSessionPayload({required this.subjectId, this.semesterId});

  final String subjectId;
  final String? semesterId;

  Map<String, dynamic> toJson() => {
        'subjectId': subjectId,
        if (semesterId != null) 'semesterId': semesterId,
      };
}
