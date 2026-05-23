import 'package:study_time_tracker/core/api/api_response.dart';
import 'package:study_time_tracker/src/domain/models/subject/subject.dart';
import 'package:study_time_tracker/src/domain/models/subject/subject_payload.dart';
import 'package:study_time_tracker/src/domain/repositories/subject_repository_intf.dart';
import 'package:study_time_tracker/src/domain/services/api_service_intf.dart';

class SubjectRepository implements ISubjectRepository {
  SubjectRepository(this._apiService);

  final IApiService _apiService;

  @override
  Future<APIListResponse<Subject>> getAll() {
    return _apiService.getList<Subject>(
      path: '/subjects',
      fromJson: Subject.fromJson,
      successMessage: 'Subjects loaded',
    );
  }

  @override
  Future<APIResponse<Subject>> create({required SubjectCreatePayload payload}) {
    return _apiService.post<Subject>(
      path: '/subjects',
      body: payload.toJson(),
      fromJson: Subject.fromJson,
      successMessage: 'Subject created',
    );
  }

  @override
  Future<APIResponse<Subject>> update({
    required String id,
    required SubjectUpdatePayload payload,
  }) {
    return _apiService.put<Subject>(
      path: '/subjects/$id',
      body: payload.toJson(),
      fromJson: Subject.fromJson,
      successMessage: 'Subject updated',
    );
  }

  @override
  Future<APIResponse<Map<String, dynamic>>> delete({required String id}) {
    return _apiService.delete<Map<String, dynamic>>(
      path: '/subjects/$id',
      fromJson: (json) => json,
      successMessage: 'Subject deleted',
    );
  }
}
