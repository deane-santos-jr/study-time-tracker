import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:study_time_tracker/src/data/services/token_storage_service.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockSecureStorage secure;
  late TokenStorageService service;

  setUp(() {
    secure = _MockSecureStorage();
    when(() => secure.read(key: any(named: 'key')))
        .thenAnswer((_) async => null);
    when(() => secure.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});
    when(() => secure.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    service = TokenStorageService(secureStorage: secure);
  });

  test('init() sets isAuthenticated=true when a refresh token is stored',
      () async {
    when(() => secure.read(key: 'refresh_token'))
        .thenAnswer((_) async => 'r');
    await service.init();
    expect(service.isAuthenticated.value, isTrue);
  });

  test('init() sets isAuthenticated=false when no refresh token is stored',
      () async {
    await service.init();
    expect(service.isAuthenticated.value, isFalse);
  });

  test('saveAccessToken flips isAuthenticated and keeps the token in memory',
      () async {
    await service.init();
    expect(service.isAuthenticated.value, isFalse);

    await service.saveAccessToken('access-1');

    expect(service.isAuthenticated.value, isTrue);
    expect(await service.getAccessToken(), equals('access-1'));
    verifyNever(() =>
        secure.write(key: 'access_token', value: any(named: 'value')));
  });

  test('isAccessTokenExpired honours the expiry buffer', () async {
    await service.saveExpiresAt(
      DateTime.now().add(const Duration(seconds: 10)),
    );
    // default buffer is 30s, so a 10s-from-now expiry counts as expired
    expect(await service.isAccessTokenExpired(), isTrue);

    await service.saveExpiresAt(
      DateTime.now().add(const Duration(minutes: 5)),
    );
    expect(await service.isAccessTokenExpired(), isFalse);
  });

  test('clearAll deletes the refresh token only — never deleteAll', () async {
    await service.saveAccessToken('a');
    await service.saveExpiresAt(
      DateTime.now().add(const Duration(minutes: 5)),
    );
    await service.clearAll();

    expect(service.isAuthenticated.value, isFalse);
    expect(await service.getAccessToken(), isNull);
    expect(await service.getExpiresAt(), isNull);
    verify(() => secure.delete(key: 'refresh_token')).called(1);
    verifyNever(() => secure.deleteAll());
  });
}
