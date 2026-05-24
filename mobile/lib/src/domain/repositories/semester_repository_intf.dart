import 'package:study_time_tracker/core/api/api_response.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester_payload.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester_stats.dart';

abstract class ISemesterRepository {
  Future<APIListResponse<Semester>> getAll();
  Future<APIResponse<Semester?>> getActive();
  Future<APIResponse<Semester>> create({required SemesterCreatePayload payload});
  Future<APIResponse<Semester>> update({
    required String id,
    required SemesterUpdatePayload payload,
  });
  Future<APIResponse<Map<String, dynamic>>> delete({required String id});
  Future<APIResponse<SemesterStats>> getStats({required String id});
}
