import 'package:study_time_tracker/core/api/api_response.dart';
import 'package:study_time_tracker/src/domain/models/authentication/auth_token.dart';
import 'package:study_time_tracker/src/domain/models/authentication/user_login.dart';
import 'package:study_time_tracker/src/domain/models/authentication/user_registration.dart';
import 'package:study_time_tracker/src/domain/repositories/authentication_repository_intf.dart';
import 'package:study_time_tracker/src/domain/services/api_service_intf.dart';

class AuthenticationRepository implements IAuthenticationRepository {
  AuthenticationRepository(this._apiService);

  final IApiService _apiService;

  @override
  Future<APIResponse<AuthToken>> login({required UserLogin userLogin}) {
    return _apiService.post<AuthToken>(
      path: '/auth/login',
      body: userLogin.toJson(),
      fromJson: AuthToken.fromJson,
      successMessage: 'Login successful',
    );
  }

  @override
  Future<APIResponse<RegisteredUser>> register({required UserRegistration registration}) {
    return _apiService.post<RegisteredUser>(
      path: '/auth/register',
      body: registration.toJson(),
      fromJson: RegisteredUser.fromJson,
      successMessage: 'Account created',
    );
  }

  @override
  Future<APIResponse<AuthToken>> refreshToken({required String refreshToken}) {
    return _apiService.post<AuthToken>(
      path: '/auth/refresh',
      body: {'refreshToken': refreshToken},
      fromJson: AuthToken.fromJson,
      successMessage: 'Token refreshed',
    );
  }

  @override
  Future<void> logOut() async {
    try {
      await _apiService.post<Map<String, dynamic>>(
        path: '/auth/logout',
        body: const <String, dynamic>{},
        fromJson: (json) => json,
        successMessage: 'Logout successful',
      );
    } catch (_) {
      // Logout is best-effort; local state will be cleared by the caller.
    }
  }
}
