import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:study_time_tracker/core/utils/core_utils.dart';
import 'package:study_time_tracker/src/domain/models/authentication/user_login.dart';
import 'package:study_time_tracker/src/domain/models/authentication/user_registration.dart';
import 'package:study_time_tracker/src/domain/repositories/authentication_repository_intf.dart';
import 'package:study_time_tracker/src/domain/services/token_storage_service_intf.dart';

part 'authentication_state.dart';

class AuthenticationCubit extends Cubit<AuthenticationState> {
  AuthenticationCubit(this.authenticationRepository, this.tokenStorageService)
      : super(AuthenticationInitial());

  final IAuthenticationRepository authenticationRepository;
  final ITokenStorageService tokenStorageService;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      emit(AuthenticationLoading());
      final response = await authenticationRepository.login(
        userLogin: UserLogin(email: email, password: password),
      );
      if (response.success && response.data != null) {
        await tokenStorageService.saveAccessToken(response.data!.accessToken);
        await tokenStorageService.saveRefreshToken(response.data!.refreshToken);
        await tokenStorageService.saveExpiresAt(response.data!.expiresAt);
        emit(const AuthenticationSuccess());
      } else {
        emit(AuthenticationFailure(errorMessage: response.message));
      }
    } catch (e) {
      emit(AuthenticationFailure(errorMessage: CoreUtils.getErrorMessage(e)));
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      emit(AuthenticationLoading());
      final response = await authenticationRepository.register(
        registration: UserRegistration(
          email: email,
          password: password,
          firstName: firstName,
          lastName: lastName,
        ),
      );
      if (response.success) {
        // Backend returns the user (no tokens) — auto-login to obtain tokens.
        await login(email: email, password: password);
      } else {
        emit(AuthenticationFailure(errorMessage: response.message));
      }
    } catch (e) {
      emit(AuthenticationFailure(errorMessage: CoreUtils.getErrorMessage(e)));
    }
  }

  Future<void> logout() async {
    emit(AuthenticationLoading());
    // Logout is best-effort: ignore server errors so we always clear local
    // state and finish in [LogoutSuccess] without flashing a Failure state.
    try {
      await authenticationRepository.logOut();
    } catch (_) {}
    await tokenStorageService.clearAll();
    emit(const LogoutSuccess());
  }
}
