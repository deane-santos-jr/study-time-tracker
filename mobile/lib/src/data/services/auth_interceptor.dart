import 'dart:async';

import 'package:dio/dio.dart';
import 'package:study_time_tracker/src/domain/repositories/authentication_repository_intf.dart';
import 'package:study_time_tracker/src/domain/services/token_storage_service_intf.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required ITokenStorageService tokenStorageService,
    required IAuthenticationRepository Function() authRepositoryFactory,
  })  : _dio = dio,
        _tokenStorageService = tokenStorageService,
        _authRepositoryFactory = authRepositoryFactory;

  final Dio _dio;
  final ITokenStorageService _tokenStorageService;
  final IAuthenticationRepository Function() _authRepositoryFactory;
  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;

  static const String _retryFlag = 'auth_retried';
  static const String _refreshPath = '/auth/refresh';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!options.headers.containsKey('Authorization')) {
      if (await _tokenStorageService.isAccessTokenExpired()) {
        await _tryRefresh();
      }
      final token = await _tokenStorageService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;
    final alreadyRetried = err.requestOptions.extra[_retryFlag] == true;

    if (status != 401 || alreadyRetried || path.contains(_refreshPath)) {
      return handler.next(err);
    }

    try {
      await _tryRefresh();
      final token = await _tokenStorageService.getAccessToken();
      if (token == null || token.isEmpty) {
        return handler.next(err);
      }

      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $token';
      retryOptions.extra[_retryFlag] = true;

      final response = await _dio.fetch<dynamic>(retryOptions);
      return handler.resolve(response);
    } catch (_) {
      return handler.next(err);
    }
  }

  Future<void> _tryRefresh() async {
    if (_isRefreshing) {
      _refreshCompleter ??= Completer<void>();
      await _refreshCompleter!.future;
      return;
    }
    _isRefreshing = true;
    _refreshCompleter = Completer<void>();
    try {
      final refresh = await _tokenStorageService.getRefreshToken();
      if (refresh == null || refresh.isEmpty) return;
      final res =
          await _authRepositoryFactory().refreshToken(refreshToken: refresh);
      if (res.success && res.data != null) {
        await _tokenStorageService.saveAccessToken(res.data!.accessToken);
        await _tokenStorageService.saveRefreshToken(res.data!.refreshToken);
        await _tokenStorageService.saveExpiresAt(res.data!.expiresAt);
      } else {
        await _tokenStorageService.clearAll();
      }
    } catch (_) {
      // swallow — caller will surface the resulting error if any
    } finally {
      _refreshCompleter?.complete();
      _refreshCompleter = null;
      _isRefreshing = false;
    }
  }
}
