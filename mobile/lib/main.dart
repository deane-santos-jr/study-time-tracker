import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/core/utils/injection_container.dart';
import 'package:study_time_tracker/core/utils/router.dart';
import 'package:study_time_tracker/src/domain/services/token_storage_service_intf.dart';
import 'package:study_time_tracker/src/presentation/modules/authentication/services/authentication_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await init();
  runApp(MyApp(tokenStorageService: sl<ITokenStorageService>()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.tokenStorageService});

  final ITokenStorageService tokenStorageService;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter(widget.tokenStorageService);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AuthenticationCubit>()),
      ],
      child: MaterialApp.router(
        title: 'Study Time Tracker',
        theme: defaultTheme,
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
      ),
    );
  }
}
