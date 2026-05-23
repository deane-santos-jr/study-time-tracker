import 'dart:typed_data';

import 'package:study_time_tracker/core/api/api_response.dart';

abstract class IApiService {
  Future<APIResponse<T>> get<T>({
    required String path,
    required T Function(Map<String, dynamic>) fromJson,
    required String successMessage,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extraHeaders,
  });

  Future<APIResponse<T?>> getNullable<T>({
    required String path,
    required T Function(Map<String, dynamic>) fromJson,
    required String successMessage,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extraHeaders,
  });

  Future<APIResponse<T>> post<T>({
    required String path,
    required T Function(Map<String, dynamic>) fromJson,
    required String successMessage,
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extraHeaders,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  });

  Future<APIResponse<T>> put<T>({
    required String path,
    required T Function(Map<String, dynamic>) fromJson,
    required String successMessage,
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extraHeaders,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  });

  Future<APIResponse<T>> delete<T>({
    required String path,
    required T Function(Map<String, dynamic>) fromJson,
    required String successMessage,
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extraHeaders,
  });

  Future<APIListResponse<T>> getList<T>({
    required String path,
    required T Function(Map<String, dynamic>) fromJson,
    required String successMessage,
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extraHeaders,
  });

  Future<Uint8List> getBytes({
    required String path,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extraHeaders,
  });
}
