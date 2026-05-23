import 'dart:async';

import 'package:dio/dio.dart';
import 'package:study_time_tracker/src/domain/repositories/authentication_repository_intf.dart';
import 'package:study_time_tracker/src/domain/services/token_storage_service_intf.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required ITokenStorageService tokenStorageService,
    required IAuthenticationRepository Function() authRepositoryFactory,
  })  : _tokenStorageService = tokenStorageService,
        _authRepositoryFactory = authRepositoryFactory;

  final ITokenStorageService _tokenStorageService;
  final IAuthenticationRepository Function() _authRepositoryFactory;
  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!options.headers.containsKey('Authorization')) {
      if (await _tokenStorageService.isAccessTokenExpired()) {
        await _tryProactiveRefresh();
      }
      final token = await _tokenStorageService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    return handler.next(options);
  }

  Future<void> _tryProactiveRefresh() async {
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
      final res = await _authRepositoryFactory().refreshToken(refreshToken: refresh);
      if (res.success && res.data != null) {
        await _tokenStorageService.saveAccessToken(res.data!.accessToken);
        await _tokenStorageService.saveRefreshToken(res.data!.refreshToken);
        await _tokenStorageService.saveExpiresAt(res.data!.expiresAt);
      } else {
        await _tokenStorageService.clearAll();
      }
    } catch (_) {
      // swallow — request will proceed and surface a 401 if needed
    } finally {
      _refreshCompleter?.complete();
      _isRefreshing = false;
    }
  }
}
