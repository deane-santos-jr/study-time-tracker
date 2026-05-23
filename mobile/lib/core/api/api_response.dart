class APIResponse<T> {
  APIResponse({
    required this.success,
    required this.message,
    required this.statusCode,
    required this.data,
  });

  final bool success;
  final String message;
  final int statusCode;
  final T? data;
}

class APIListResponse<T> {
  APIListResponse({
    required this.success,
    required this.message,
    required this.statusCode,
    required this.data,
  });

  final bool success;
  final String message;
  final int statusCode;
  final List<T> data;
}
