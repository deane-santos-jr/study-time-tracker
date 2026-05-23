import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:study_time_tracker/core/api/api_response.dart';
import 'package:study_time_tracker/src/data/services/auth_interceptor.dart';
import 'package:study_time_tracker/src/domain/models/authentication/auth_token.dart';
import 'package:study_time_tracker/src/domain/repositories/authentication_repository_intf.dart';
import 'package:study_time_tracker/src/domain/services/token_storage_service_intf.dart';

class _MockDio extends Mock implements Dio {}

class _MockAuthRepository extends Mock implements IAuthenticationRepository {}

class _MockTokenStorage extends Mock implements ITokenStorageService {}

class _MockErrorHandler extends Mock implements ErrorInterceptorHandler {}

class _MockRequestHandler extends Mock implements RequestInterceptorHandler {}

class _FakeRequestOptions extends Fake implements RequestOptions {}

class _FakeDioException extends Fake implements DioException {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeRequestOptions());
    registerFallbackValue(_FakeDioException());
  });

  late _MockDio dio;
  late _MockAuthRepository repo;
  late _MockTokenStorage storage;
  late AuthInterceptor interceptor;

  setUp(() {
    dio = _MockDio();
    repo = _MockAuthRepository();
    storage = _MockTokenStorage();
    interceptor = AuthInterceptor(
      dio: dio,
      tokenStorageService: storage,
      authRepositoryFactory: () => repo,
    );

    when(() => storage.getRefreshToken()).thenAnswer((_) async => 'r');
    when(() => storage.saveAccessToken(any())).thenAnswer((_) async {});
    when(() => storage.saveRefreshToken(any())).thenAnswer((_) async {});
    when(() => storage.saveExpiresAt(any())).thenAnswer((_) async {});
    when(() => storage.clearAll()).thenAnswer((_) async {});
  });

  test('onError(401) refreshes, retries the request, and resolves the response',
      () async {
    when(() => repo.refreshToken(refreshToken: any(named: 'refreshToken')))
        .thenAnswer(
      (_) async => APIResponse<AuthToken>(
        success: true,
        message: 'ok',
        statusCode: 200,
        data: AuthToken(
          accessToken: 'new-access',
          refreshToken: 'new-refresh',
          expiresAt: DateTime.now().add(const Duration(minutes: 15)),
        ),
      ),
    );
    when(() => storage.getAccessToken()).thenAnswer((_) async => 'new-access');

    final retryResponse = Response<dynamic>(
      requestOptions: RequestOptions(path: '/subjects'),
      statusCode: 200,
      data: {'success': true},
    );
    when(() => dio.fetch<dynamic>(any())).thenAnswer((_) async => retryResponse);

    final err = DioException(
      requestOptions: RequestOptions(path: '/subjects'),
      response: Response(
        requestOptions: RequestOptions(path: '/subjects'),
        statusCode: 401,
      ),
    );
    final handler = _MockErrorHandler();

    await interceptor.onError(err, handler);

    verify(() => repo.refreshToken(refreshToken: 'r')).called(1);
    final captured =
        verify(() => dio.fetch<dynamic>(captureAny())).captured.single
            as RequestOptions;
    expect(captured.headers['Authorization'], 'Bearer new-access');
    expect(captured.extra['auth_retried'], isTrue);
    verify(() => handler.resolve(retryResponse)).called(1);
    verifyNever(() => handler.next(any()));
  });

  test('onError passes through non-401 errors without refreshing', () async {
    final err = DioException(
      requestOptions: RequestOptions(path: '/subjects'),
      response: Response(
        requestOptions: RequestOptions(path: '/subjects'),
        statusCode: 500,
      ),
    );
    final handler = _MockErrorHandler();

    await interceptor.onError(err, handler);

    verifyNever(() => repo.refreshToken(refreshToken: any(named: 'refreshToken')));
    verifyNever(() => dio.fetch<dynamic>(any()));
    verify(() => handler.next(err)).called(1);
  });

  test('onError on /auth/refresh does not loop — passes through', () async {
    final err = DioException(
      requestOptions: RequestOptions(path: '/auth/refresh'),
      response: Response(
        requestOptions: RequestOptions(path: '/auth/refresh'),
        statusCode: 401,
      ),
    );
    final handler = _MockErrorHandler();

    await interceptor.onError(err, handler);

    verifyNever(() => repo.refreshToken(refreshToken: any(named: 'refreshToken')));
    verify(() => handler.next(err)).called(1);
  });

  test('onError does not retry a request flagged as already retried',
      () async {
    final options = RequestOptions(path: '/subjects')..extra['auth_retried'] = true;
    final err = DioException(
      requestOptions: options,
      response: Response(requestOptions: options, statusCode: 401),
    );
    final handler = _MockErrorHandler();

    await interceptor.onError(err, handler);

    verifyNever(() => repo.refreshToken(refreshToken: any(named: 'refreshToken')));
    verify(() => handler.next(err)).called(1);
  });

  test(
      'onRequest on /auth/refresh bypasses token logic — prevents '
      'cold-launch deadlock', () async {
    // If onRequest tried to refresh on a refresh request, it would await
    // its own completion forever. This test guards against that path:
    // the storage's isAccessTokenExpired must NEVER be consulted, and the
    // refresh repo must NEVER be invoked, when the outgoing request is the
    // refresh call itself.
    final options = RequestOptions(path: '/auth/refresh');
    final handler = _MockRequestHandler();

    await interceptor.onRequest(options, handler);

    verifyNever(() => storage.isAccessTokenExpired());
    verifyNever(() => repo.refreshToken(refreshToken: any(named: 'refreshToken')));
    verify(() => handler.next(options)).called(1);
    expect(options.headers.containsKey('Authorization'), isFalse);
  });
}
