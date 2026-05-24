import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:study_time_tracker/core/utils/constants.dart';
import 'package:study_time_tracker/src/data/repositories/analytics_repository.dart';
import 'package:study_time_tracker/src/data/repositories/authentication_repository.dart';
import 'package:study_time_tracker/src/data/repositories/semester_repository.dart';
import 'package:study_time_tracker/src/data/repositories/session_repository.dart';
import 'package:study_time_tracker/src/data/repositories/subject_repository.dart';
import 'package:study_time_tracker/src/data/services/auth_interceptor.dart';
import 'package:study_time_tracker/src/data/services/dio_api_service.dart';
import 'package:study_time_tracker/src/data/services/token_storage_service.dart';
import 'package:study_time_tracker/src/domain/repositories/analytics_repository_intf.dart';
import 'package:study_time_tracker/src/domain/repositories/authentication_repository_intf.dart';
import 'package:study_time_tracker/src/domain/repositories/semester_repository_intf.dart';
import 'package:study_time_tracker/src/domain/repositories/session_repository_intf.dart';
import 'package:study_time_tracker/src/domain/repositories/subject_repository_intf.dart';
import 'package:study_time_tracker/src/domain/services/api_service_intf.dart';
import 'package:study_time_tracker/src/domain/services/token_storage_service_intf.dart';
import 'package:study_time_tracker/src/presentation/modules/authentication/services/authentication_cubit.dart';
import 'package:study_time_tracker/src/presentation/modules/study/dashboard/services/active_session_cubit.dart';
import 'package:study_time_tracker/src/presentation/modules/study/dashboard/services/dashboard_stats_cubit.dart';
import 'package:study_time_tracker/src/presentation/modules/study/semesters/services/semesters_cubit.dart';
import 'package:study_time_tracker/src/presentation/modules/subjects/services/subjects_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // MARK: core-services-start
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
  // MARK: core-services-end

  // MARK: authentication-repositories-start
  sl.registerLazySingleton<IAuthenticationRepository>(
    () => AuthenticationRepository(sl<IApiService>()),
  );
  // MARK: authentication-repositories-end

  // MARK: subjects-repositories-start
  sl.registerLazySingleton<ISubjectRepository>(
    () => SubjectRepository(sl<IApiService>()),
  );
  sl.registerLazySingleton<ISemesterRepository>(
    () => SemesterRepository(sl<IApiService>()),
  );
  // MARK: subjects-repositories-end

  // MARK: sessions-repositories-start
  sl.registerLazySingleton<ISessionRepository>(
    () => SessionRepository(sl<IApiService>()),
  );
  // MARK: sessions-repositories-end

  // MARK: analytics-repositories-start
  sl.registerLazySingleton<IAnalyticsRepository>(
    () => AnalyticsRepository(sl<IApiService>()),
  );
  // MARK: analytics-repositories-end

  // MARK: authentication-cubits-start
  sl.registerFactory(
    () => AuthenticationCubit(
      sl<IAuthenticationRepository>(),
      sl<ITokenStorageService>(),
    ),
  );
  // MARK: authentication-cubits-end

  // MARK: subjects-cubits-start
  sl.registerFactory(
    () => SubjectsCubit(subjectRepository: sl<ISubjectRepository>()),
  );
  // MARK: subjects-cubits-end

  // MARK: semesters-cubits-start
  sl.registerFactory(
    () => SemestersCubit(semesterRepository: sl<ISemesterRepository>()),
  );
  // MARK: semesters-cubits-end

  // MARK: sessions-cubits-start
  sl.registerFactory(
    () => ActiveSessionCubit(sessionRepository: sl<ISessionRepository>()),
  );
  // MARK: sessions-cubits-end

  // MARK: analytics-cubits-start
  sl.registerFactory(
    () => DashboardStatsCubit(
      analyticsRepository: sl<IAnalyticsRepository>(),
      sessionRepository: sl<ISessionRepository>(),
    ),
  );
  // MARK: analytics-cubits-end
}
