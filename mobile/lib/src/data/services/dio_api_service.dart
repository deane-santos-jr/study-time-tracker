import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:study_time_tracker/core/api/api_error_response.dart';
import 'package:study_time_tracker/core/api/api_response.dart';
import 'package:study_time_tracker/core/api/http_messages.dart';
import 'package:study_time_tracker/core/utils/constants.dart';
import 'package:study_time_tracker/src/domain/services/api_service_intf.dart';

/// Adapted from the activework-flutter-client reference. The Study Time Tracker
/// backend uses a flat envelope (`{ success, message, data? }`) rather than the
/// reference's nested `meta`/`data` shape, so the parsing here is flattened.
class DioApiService implements IApiService {
  DioApiService({List<Interceptor> interceptors = const [], Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: kApiBaseUrl,
                headers: kDefaultHeaders,
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
              ),
            ) {
    _dio.interceptors.addAll(interceptors);
  }

  final Dio _dio;

  @override
  Future<APIResponse<T>> get<T>({
    required String path,
    required T Function(Map<String, dynamic>) fromJson,
    required String successMessage,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extraHeaders,
  }) {
    return _execute(
      () => _dio.get(path,
          queryParameters: queryParameters, options: _optionsFrom(extraHeaders)),
      fromJson,
      successMessage,
    );
  }

  @override
  Future<APIResponse<T?>> getNullable<T>({
    required String path,
    required T Function(Map<String, dynamic>) fromJson,
    required String successMessage,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extraHeaders,
  }) async {
    try {
      final response = await _dio.get(path,
          queryParameters: queryParameters, options: _optionsFrom(extraHeaders));
      final envelope = response.data as Map<String, dynamic>;
      final data = envelope['data'];
      return APIResponse(
        success: (envelope['success'] as bool?) ?? true,
        message: (envelope['message'] as String?) ?? successMessage,
        statusCode: response.statusCode ?? 200,
        data: data is Map<String, dynamic> ? fromJson(data) : null,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on SocketException {
      throw httpNoConnectionError();
    }
  }

  @override
  Future<APIResponse<T>> post<T>({
    required String path,
    required T Function(Map<String, dynamic>) fromJson,
    required String successMessage,
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extraHeaders,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) {
    return _execute(
      () => _dio.post(
        path,
        data: body,
        queryParameters: queryParameters,
        options: _optionsFrom(extraHeaders),
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ),
      fromJson,
      successMessage,
    );
  }

  @override
  Future<APIResponse<T>> put<T>({
    required String path,
    required T Function(Map<String, dynamic>) fromJson,
    required String successMessage,
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extraHeaders,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) {
    return _execute(
      () => _dio.put(
        path,
        data: body,
        queryParameters: queryParameters,
        options: _optionsFrom(extraHeaders),
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ),
      fromJson,
      successMessage,
    );
  }

  @override
  Future<APIResponse<T>> delete<T>({
    required String path,
    required T Function(Map<String, dynamic>) fromJson,
    required String successMessage,
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extraHeaders,
  }) {
    return _execute(
      () => _dio.delete(
        path,
        data: body,
        queryParameters: queryParameters,
        options: _optionsFrom(extraHeaders),
      ),
      fromJson,
      successMessage,
    );
  }

  @override
  Future<APIListResponse<T>> getList<T>({
    required String path,
    required T Function(Map<String, dynamic>) fromJson,
    required String successMessage,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extraHeaders,
  }) {
    return _executeList(
      () => _dio.get(
        path,
        queryParameters: queryParameters,
        options: _optionsFrom(extraHeaders),
      ),
      fromJson,
      successMessage,
    );
  }

  @override
  Future<APIListResponse<T>> postList<T>({
    required String path,
    required T Function(Map<String, dynamic>) fromJson,
    required String successMessage,
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extraHeaders,
  }) {
    return _executeList(
      () => _dio.post(
        path,
        data: body,
        queryParameters: queryParameters,
        options: _optionsFrom(extraHeaders),
      ),
      fromJson,
      successMessage,
    );
  }

  Future<APIListResponse<T>> _executeList<T>(
    Future<Response> Function() request,
    T Function(Map<String, dynamic>) fromJson,
    String successMessage,
  ) async {
    try {
      final response = await request();
      final envelope = response.data as Map<String, dynamic>;
      final data = (envelope['data'] as List<dynamic>? ?? const []);
      return APIListResponse(
        success: (envelope['success'] as bool?) ?? true,
        message: (envelope['message'] as String?) ?? successMessage,
        statusCode: response.statusCode ?? 200,
        data: data
            .map((json) => fromJson(json as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on SocketException {
      throw httpNoConnectionError();
    }
  }

  @override
  Future<Uint8List> getBytes({
    required String path,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extraHeaders,
  }) async {
    try {
      final response = await _dio.get<List<int>>(
        path,
        queryParameters: queryParameters,
        options: Options(
          headers: extraHeaders,
          responseType: ResponseType.bytes,
        ),
      );
      return Uint8List.fromList(response.data ?? const <int>[]);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on SocketException {
      throw httpNoConnectionError();
    }
  }

  Future<APIResponse<T>> _execute<T>(
    Future<Response> Function() request,
    T Function(Map<String, dynamic>) fromJson,
    String successMessage,
  ) async {
    try {
      final response = await request();
      final envelope = response.data as Map<String, dynamic>;
      final data = envelope['data'] as Map<String, dynamic>?;
      return APIResponse(
        success: (envelope['success'] as bool?) ?? true,
        message: (envelope['message'] as String?) ?? successMessage,
        statusCode: response.statusCode ?? 200,
        data: data != null ? fromJson(data) : null,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on SocketException {
      throw httpNoConnectionError();
    }
  }

  APIErrorResponse _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return httpNoConnectionError();
    }
    final responseData = e.response?.data;
    if (responseData is Map<String, dynamic>) {
      return APIErrorResponse(
        message: (responseData['message'] as String?) ??
            e.message ??
            'An unexpected error occurred',
        statusCode: e.response?.statusCode,
      );
    }
    return APIErrorResponse(
      message: e.message ?? 'An unexpected error occurred',
      statusCode: e.response?.statusCode,
    );
  }

  Options? _optionsFrom(Map<String, dynamic>? extraHeaders) {
    if (extraHeaders == null) return null;
    return Options(headers: extraHeaders);
  }
}
