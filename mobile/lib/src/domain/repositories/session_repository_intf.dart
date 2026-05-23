import 'package:study_time_tracker/core/api/api_response.dart';
import 'package:study_time_tracker/src/domain/models/session/session_payload.dart';
import 'package:study_time_tracker/src/domain/models/session/study_session.dart';

abstract class ISessionRepository {
  Future<APIResponse<StudySession?>> getActive();
  Future<APIListResponse<StudySession>> getAll();
  Future<APIResponse<StudySession>> start({required StartSessionPayload payload});
  Future<APIResponse<StudySession>> pause({required String id});
  Future<APIResponse<StudySession>> resume({required String id});
  Future<APIResponse<StudySession>> stop({required String id});
}
