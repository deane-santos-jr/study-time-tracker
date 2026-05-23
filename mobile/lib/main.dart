import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/core/utils/injection_container.dart';
import 'package:study_time_tracker/core/utils/router.dart';
import 'package:study_time_tracker/src/domain/services/token_storage_service_intf.dart';
import 'package:study_time_tracker/src/presentation/modules/authentication/services/authentication_cubit.dart';
import 'package:study_time_tracker/src/presentation/modules/study/shell/service/study_shell_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await init();
  runApp(MyApp(tokenStorageService: sl<ITokenStorageService>()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.tokenStorageService});

  final ITokenStorageService tokenStorageService;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AuthenticationCubit>()),
        // MARK: study-shell-provider-start
        BlocProvider(create: (_) => sl<StudyShellCubit>()),
        // MARK: study-shell-provider-end
      ],
      child: MaterialApp.router(
        title: 'Study Time Tracker',
        theme: defaultTheme,
        debugShowCheckedModeBanner: false,
        routerConfig: createRouter(tokenStorageService),
      ),
    );
  }
}
