import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:study_time_tracker/core/api/api_response.dart';
import 'package:study_time_tracker/src/domain/models/user/user_profile.dart';
import 'package:study_time_tracker/src/domain/repositories/authentication_repository_intf.dart';
import 'package:study_time_tracker/src/domain/services/token_storage_service_intf.dart';
import 'package:study_time_tracker/src/presentation/modules/profile/services/profile_cubit.dart';

class _MockAuthRepository extends Mock implements IAuthenticationRepository {}

class _MockTokenStorage extends Mock implements ITokenStorageService {}

UserProfile _profile({
  String id = 'user-1',
  String email = 'someone@example.com',
  String firstName = 'Jamie',
  String lastName = 'Reyes',
}) {
  return UserProfile(
    id: id,
    email: email,
    firstName: firstName,
    lastName: lastName,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late _MockAuthRepository repo;
  late _MockTokenStorage storage;

  setUp(() {
    repo = _MockAuthRepository();
    storage = _MockTokenStorage();
  });

  blocTest<ProfileCubit, ProfileState>(
    'load() emits Loading then Loaded with the fetched profile',
    build: () {
      when(() => repo.getProfile()).thenAnswer(
        (_) async => APIResponse<UserProfile>(
          success: true,
          message: 'ok',
          statusCode: 200,
          data: _profile(),
        ),
      );
      return ProfileCubit(authRepository: repo, tokenStorage: storage);
    },
    act: (c) => c.load(),
    expect: () => [
      isA<ProfileLoading>(),
      isA<ProfileLoaded>()
          .having((s) => s.profile.email, 'email', 'someone@example.com')
          .having((s) => s.deleting, 'deleting', false)
          .having((s) => s.deleteError, 'deleteError', isNull),
    ],
  );

  blocTest<ProfileCubit, ProfileState>(
    'load() emits Loading then Error when the repository throws',
    build: () {
      when(() => repo.getProfile()).thenThrow(Exception('network down'));
      return ProfileCubit(authRepository: repo, tokenStorage: storage);
    },
    act: (c) => c.load(),
    expect: () => [
      isA<ProfileLoading>(),
      isA<ProfileError>().having(
        (s) => s.errorMessage,
        'errorMessage',
        isNotEmpty,
      ),
    ],
  );

  blocTest<ProfileCubit, ProfileState>(
    'deleteAccount() success: emits deleting=true, clears tokens, emits Deleted',
    build: () {
      when(() => repo.deleteAccount(password: any(named: 'password')))
          .thenAnswer(
        (_) async => APIResponse<Map<String, dynamic>>(
          success: true,
          message: 'ok',
          statusCode: 200,
          data: const {},
        ),
      );
      when(() => storage.clearAll()).thenAnswer((_) async {});
      return ProfileCubit(authRepository: repo, tokenStorage: storage);
    },
    seed: () => ProfileLoaded(profile: _profile()),
    act: (c) => c.deleteAccount(password: 'Password123!'),
    expect: () => [
      isA<ProfileLoaded>()
          .having((s) => s.deleting, 'deleting', true)
          .having((s) => s.deleteError, 'deleteError', isNull),
      isA<ProfileDeleted>(),
    ],
    verify: (_) {
      verify(() => repo.deleteAccount(password: 'Password123!')).called(1);
      verify(() => storage.clearAll()).called(1);
    },
  );

  blocTest<ProfileCubit, ProfileState>(
    'deleteAccount() failure: emits deleting=true, then deleting=false with deleteError',
    build: () {
      when(() => repo.deleteAccount(password: any(named: 'password')))
          .thenThrow(Exception('wrong password'));
      return ProfileCubit(authRepository: repo, tokenStorage: storage);
    },
    seed: () => ProfileLoaded(profile: _profile()),
    act: (c) => c.deleteAccount(password: 'WrongPassword!'),
    expect: () => [
      isA<ProfileLoaded>().having((s) => s.deleting, 'deleting', true),
      isA<ProfileLoaded>()
          .having((s) => s.deleting, 'deleting', false)
          .having((s) => s.deleteError, 'deleteError', isNotEmpty)
          .having((s) => s.profile.email, 'profile preserved',
              'someone@example.com'),
    ],
    verify: (_) {
      verifyNever(() => storage.clearAll());
    },
  );

  blocTest<ProfileCubit, ProfileState>(
    'deleteAccount() is a no-op when not in ProfileLoaded',
    build: () => ProfileCubit(authRepository: repo, tokenStorage: storage),
    act: (c) => c.deleteAccount(password: 'whatever'),
    expect: () => const <ProfileState>[],
    verify: (_) {
      verifyNever(() => repo.deleteAccount(password: any(named: 'password')));
      verifyNever(() => storage.clearAll());
    },
  );

  // Sanity: storage exposes a ValueListenable that the router watches. Make
  // sure ProfileCubit doesn't accidentally touch it (we mutate it via clearAll
  // side-effect on the real impl).
  test('does not subscribe to or mutate the isAuthenticated notifier directly',
      () {
    final notifier = ValueNotifier<bool>(true);
    when(() => storage.isAuthenticated).thenReturn(notifier);
    final cubit = ProfileCubit(authRepository: repo, tokenStorage: storage);
    cubit.close();
    verifyNever(() => storage.isAuthenticated);
  });
}
