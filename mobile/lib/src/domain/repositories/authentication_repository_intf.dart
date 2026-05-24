import 'package:study_time_tracker/core/api/api_response.dart';
import 'package:study_time_tracker/src/domain/models/authentication/auth_token.dart';
import 'package:study_time_tracker/src/domain/models/authentication/user_login.dart';
import 'package:study_time_tracker/src/domain/models/authentication/user_registration.dart';
import 'package:study_time_tracker/src/domain/models/user/user_profile.dart';

abstract class IAuthenticationRepository {
  Future<APIResponse<AuthToken>> login({required UserLogin userLogin});
  Future<APIResponse<RegisteredUser>> register({required UserRegistration registration});
  Future<APIResponse<AuthToken>> refreshToken({required String refreshToken});
  Future<APIResponse<UserProfile>> getProfile();
  Future<APIResponse<Map<String, dynamic>>> deleteAccount({
    required String password,
  });
  Future<void> logOut();
}
