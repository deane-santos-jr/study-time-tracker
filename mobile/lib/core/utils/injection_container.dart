import 'package:get_it/get_it.dart';
import 'package:study_time_tracker/src/data/repositories/authentication_repository.dart';
import 'package:study_time_tracker/src/data/services/auth_interceptor.dart';
import 'package:study_time_tracker/src/data/services/dio_api_service.dart';
import 'package:study_time_tracker/src/data/services/token_storage_service.dart';
import 'package:study_time_tracker/src/domain/repositories/authentication_repository_intf.dart';
import 'package:study_time_tracker/src/domain/services/api_service_intf.dart';
import 'package:study_time_tracker/src/domain/services/token_storage_service_intf.dart';
import 'package:study_time_tracker/src/presentation/modules/authentication/services/authentication_cubit.dart';
import 'package:study_time_tracker/src/presentation/modules/study/shell/service/study_shell_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Services
  sl.registerLazySingleton<ITokenStorageService>(() => TokenStorageService());
  sl.registerLazySingleton<AuthInterceptor>(
    () => AuthInterceptor(
      tokenStorageService: sl<ITokenStorageService>(),
      authRepositoryFactory: () => sl<IAuthenticationRepository>(),
    ),
  );
  sl.registerLazySingleton<IApiService>(
    () => DioApiService(interceptors: [sl<AuthInterceptor>()]),
  );

  // Repositories
  sl.registerLazySingleton<IAuthenticationRepository>(
    () => AuthenticationRepository(sl<IApiService>()),
  );

  // Cubits
  sl.registerFactory(
    () => AuthenticationCubit(
      sl<IAuthenticationRepository>(),
      sl<ITokenStorageService>(),
    ),
  );
  // MARK: study-shell-di-start
  sl.registerFactory(() => StudyShellCubit());
  // MARK: study-shell-di-end
}
