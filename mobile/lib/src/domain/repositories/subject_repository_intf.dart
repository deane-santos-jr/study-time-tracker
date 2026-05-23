import 'package:study_time_tracker/core/api/api_response.dart';
import 'package:study_time_tracker/src/domain/models/subject/subject.dart';
import 'package:study_time_tracker/src/domain/models/subject/subject_payload.dart';

abstract class ISubjectRepository {
  Future<APIListResponse<Subject>> getAll();
  Future<APIResponse<Subject>> create({required SubjectCreatePayload payload});
  Future<APIResponse<Subject>> update({
    required String id,
    required SubjectUpdatePayload payload,
  });
  Future<APIResponse<Map<String, dynamic>>> delete({required String id});
}
