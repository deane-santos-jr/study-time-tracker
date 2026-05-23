class APIErrorResponse implements Exception {
  APIErrorResponse({
    required this.message,
    this.statusCode,
  });

  final String message;
  final int? statusCode;

  @override
  String toString() => 'APIErrorResponse($statusCode, $message)';
}
