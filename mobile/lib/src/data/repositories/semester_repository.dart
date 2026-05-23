import 'package:study_time_tracker/core/api/api_response.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester_payload.dart';
import 'package:study_time_tracker/src/domain/repositories/semester_repository_intf.dart';
import 'package:study_time_tracker/src/domain/services/api_service_intf.dart';

class SemesterRepository implements ISemesterRepository {
  SemesterRepository(this._apiService);

  final IApiService _apiService;

  @override
  Future<APIListResponse<Semester>> getAll() {
    return _apiService.getList<Semester>(
      path: '/semesters',
      fromJson: Semester.fromJson,
      successMessage: 'Semesters loaded',
    );
  }

  @override
  Future<APIResponse<Semester?>> getActive() {
    return _apiService.getNullable<Semester>(
      path: '/semesters/active',
      fromJson: Semester.fromJson,
      successMessage: 'Active semester loaded',
    );
  }

  @override
  Future<APIResponse<Semester>> create({required SemesterCreatePayload payload}) {
    return _apiService.post<Semester>(
      path: '/semesters',
      body: payload.toJson(),
      fromJson: Semester.fromJson,
      successMessage: 'Semester created',
    );
  }
}
