import 'package:study_time_tracker/core/api/api_response.dart';
import 'package:study_time_tracker/src/domain/models/authentication/auth_token.dart';
import 'package:study_time_tracker/src/domain/models/authentication/user_login.dart';
import 'package:study_time_tracker/src/domain/models/authentication/user_registration.dart';

abstract class IAuthenticationRepository {
  Future<APIResponse<AuthToken>> login({required UserLogin userLogin});
  Future<APIResponse<RegisteredUser>> register({required UserRegistration registration});
  Future<APIResponse<AuthToken>> refreshToken({required String refreshToken});
  Future<void> logOut();
}
