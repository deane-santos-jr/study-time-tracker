import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:study_time_tracker/core/api/api_response.dart';
import 'package:study_time_tracker/src/domain/models/authentication/auth_token.dart';
import 'package:study_time_tracker/src/domain/models/authentication/user_login.dart';
import 'package:study_time_tracker/src/domain/repositories/authentication_repository_intf.dart';
import 'package:study_time_tracker/src/domain/services/token_storage_service_intf.dart';
import 'package:study_time_tracker/src/presentation/modules/authentication/services/authentication_cubit.dart';

class _MockAuthRepository extends Mock implements IAuthenticationRepository {}

class _MockTokenStorage extends Mock implements ITokenStorageService {}

class _FakeUserLogin extends Fake implements UserLogin {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeUserLogin());
  });

  late _MockAuthRepository repo;
  late _MockTokenStorage storage;

  setUp(() {
    repo = _MockAuthRepository();
    storage = _MockTokenStorage();
    when(() => storage.saveAccessToken(any())).thenAnswer((_) async {});
    when(() => storage.saveRefreshToken(any())).thenAnswer((_) async {});
    when(() => storage.saveExpiresAt(any())).thenAnswer((_) async {});
    when(() => storage.clearAll()).thenAnswer((_) async {});
    when(() => storage.isAuthenticated)
        .thenReturn(ValueNotifier<bool>(false));
  });

  group('AuthenticationCubit.login', () {
    blocTest<AuthenticationCubit, AuthenticationState>(
      'emits Loading then Success on a successful login',
      build: () {
        when(() => repo.login(userLogin: any(named: 'userLogin'))).thenAnswer(
          (_) async => APIResponse<AuthToken>(
            success: true,
            message: 'ok',
            statusCode: 200,
            data: AuthToken(
              accessToken: 'a',
              refreshToken: 'r',
              expiresAt: DateTime.now().add(const Duration(minutes: 15)),
            ),
          ),
        );
        return AuthenticationCubit(repo, storage);
      },
      act: (c) => c.login(email: 'jane@example.com', password: 'pw'),
      expect: () => [
        isA<AuthenticationLoading>(),
        isA<AuthenticationSuccess>(),
      ],
      verify: (_) {
        verify(() => storage.saveAccessToken('a')).called(1);
        verify(() => storage.saveRefreshToken('r')).called(1);
        verify(() => storage.saveExpiresAt(any())).called(1);
      },
    );

    blocTest<AuthenticationCubit, AuthenticationState>(
      'emits Loading then Failure when the repository returns success=false',
      build: () {
        when(() => repo.login(userLogin: any(named: 'userLogin'))).thenAnswer(
          (_) async => APIResponse<AuthToken>(
            success: false,
            message: 'Invalid credentials',
            statusCode: 401,
            data: null,
          ),
        );
        return AuthenticationCubit(repo, storage);
      },
      act: (c) => c.login(email: 'jane@example.com', password: 'pw'),
      expect: () => [
        isA<AuthenticationLoading>(),
        predicate<AuthenticationFailure>(
          (s) => s.errorMessage == 'Invalid credentials',
        ),
      ],
    );
  });

  group('AuthenticationCubit.logout', () {
    blocTest<AuthenticationCubit, AuthenticationState>(
      'always finishes in LogoutSuccess even when the API call throws',
      build: () {
        when(() => repo.logOut()).thenThrow(Exception('network down'));
        return AuthenticationCubit(repo, storage);
      },
      act: (c) => c.logout(),
      expect: () => [
        isA<AuthenticationLoading>(),
        isA<LogoutSuccess>(),
      ],
      verify: (_) => verify(() => storage.clearAll()).called(1),
    );
  });
}
