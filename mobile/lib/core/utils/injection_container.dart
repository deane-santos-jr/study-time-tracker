import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:study_time_tracker/core/utils/constants.dart';
import 'package:study_time_tracker/src/data/repositories/authentication_repository.dart';
import 'package:study_time_tracker/src/data/services/auth_interceptor.dart';
import 'package:study_time_tracker/src/data/services/dio_api_service.dart';
import 'package:study_time_tracker/src/data/services/token_storage_service.dart';
import 'package:study_time_tracker/src/domain/repositories/authentication_repository_intf.dart';
import 'package:study_time_tracker/src/domain/services/api_service_intf.dart';
import 'package:study_time_tracker/src/domain/services/token_storage_service_intf.dart';
import 'package:study_time_tracker/src/presentation/modules/authentication/services/authentication_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Services
  final tokenStorage = TokenStorageService();
  await tokenStorage.init();
  sl.registerSingleton<ITokenStorageService>(tokenStorage);

  final dio = Dio(
    BaseOptions(
      baseUrl: kApiBaseUrl,
      headers: kDefaultHeaders,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  final authInterceptor = AuthInterceptor(
    dio: dio,
    tokenStorageService: tokenStorage,
    authRepositoryFactory: () => sl<IAuthenticationRepository>(),
  );
  dio.interceptors.add(authInterceptor);

  sl.registerSingleton<AuthInterceptor>(authInterceptor);
  sl.registerSingleton<IApiService>(DioApiService(dio: dio));

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
}
