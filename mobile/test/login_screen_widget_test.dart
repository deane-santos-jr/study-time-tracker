import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/src/domain/repositories/authentication_repository_intf.dart';
import 'package:study_time_tracker/src/domain/services/token_storage_service_intf.dart';
import 'package:study_time_tracker/src/presentation/modules/authentication/screens/login_screen.dart';
import 'package:study_time_tracker/src/presentation/modules/authentication/services/authentication_cubit.dart';

class _MockAuthRepository extends Mock implements IAuthenticationRepository {}

class _MockTokenStorage extends Mock implements ITokenStorageService {}

void main() {
  testWidgets('LoginScreen renders sign-in form with sign-up link',
      (tester) async {
    final repo = _MockAuthRepository();
    final storage = _MockTokenStorage();
    when(() => storage.isAuthenticated)
        .thenReturn(ValueNotifier<bool>(false));

    await tester.pumpWidget(
      MaterialApp(
        theme: defaultTheme,
        home: BlocProvider(
          create: (_) => AuthenticationCubit(repo, storage),
          child: const LoginScreen(),
        ),
      ),
    );

    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Email *'), findsOneWidget);
    expect(find.text('Password *'), findsOneWidget);
    expect(find.text("Don't have an account? Sign up"), findsOneWidget);
  });
}
