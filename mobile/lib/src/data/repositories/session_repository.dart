import 'package:study_time_tracker/core/api/api_response.dart';
import 'package:study_time_tracker/src/domain/models/session/session_payload.dart';
import 'package:study_time_tracker/src/domain/models/session/study_session.dart';
import 'package:study_time_tracker/src/domain/repositories/session_repository_intf.dart';
import 'package:study_time_tracker/src/domain/services/api_service_intf.dart';

class SessionRepository implements ISessionRepository {
  SessionRepository(this._apiService);

  final IApiService _apiService;

  @override
  Future<APIResponse<StudySession?>> getActive() {
    return _apiService.getNullable<StudySession>(
      path: '/sessions/active',
      fromJson: StudySession.fromJson,
      successMessage: 'Active session loaded',
    );
  }

  @override
  Future<APIListResponse<StudySession>> getAll() {
    return _apiService.getList<StudySession>(
      path: '/sessions',
      fromJson: StudySession.fromJson,
      successMessage: 'Sessions loaded',
    );
  }

  @override
  Future<APIResponse<StudySession>> start({required StartSessionPayload payload}) {
    return _apiService.post<StudySession>(
      path: '/sessions/start',
      body: payload.toJson(),
      fromJson: StudySession.fromJson,
      successMessage: 'Session started',
    );
  }

  @override
  Future<APIResponse<StudySession>> pause({required String id}) {
    return _apiService.post<StudySession>(
      path: '/sessions/$id/pause',
      body: const <String, dynamic>{},
      fromJson: StudySession.fromJson,
      successMessage: 'Session paused',
    );
  }

  @override
  Future<APIResponse<StudySession>> resume({required String id}) {
    return _apiService.post<StudySession>(
      path: '/sessions/$id/resume',
      body: const <String, dynamic>{},
      fromJson: StudySession.fromJson,
      successMessage: 'Session resumed',
    );
  }

  @override
  Future<APIResponse<StudySession>> stop({required String id}) {
    return _apiService.post<StudySession>(
      path: '/sessions/$id/stop',
      body: const <String, dynamic>{},
      fromJson: StudySession.fromJson,
      successMessage: 'Session stopped',
    );
  }
}
