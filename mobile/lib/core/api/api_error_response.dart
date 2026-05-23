class APIErrorResponse implements Exception {
  APIErrorResponse({
    required this.message,
    this.statusCode,
  });

  factory APIErrorResponse.fromResponseJson(Map<String, dynamic> json) {
    return APIErrorResponse(
      message: (json['message'] as String?) ?? 'Unknown error',
      statusCode: json['statusCode'] as int?,
    );
  }

  final String message;
  final int? statusCode;

  @override
  String toString() => 'APIErrorResponse($statusCode, $message)';
}
