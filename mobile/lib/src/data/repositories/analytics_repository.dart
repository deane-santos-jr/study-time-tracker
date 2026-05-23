import 'package:study_time_tracker/core/api/api_response.dart';
import 'package:study_time_tracker/src/domain/models/analytics/analytics_summary.dart';
import 'package:study_time_tracker/src/domain/repositories/analytics_repository_intf.dart';
import 'package:study_time_tracker/src/domain/services/api_service_intf.dart';

class AnalyticsRepository implements IAnalyticsRepository {
  AnalyticsRepository(this._apiService);

  final IApiService _apiService;

  @override
  Future<APIResponse<AnalyticsSummary>> getSummary() {
    return _apiService.get<AnalyticsSummary>(
      path: '/analytics',
      fromJson: AnalyticsSummary.fromJson,
      successMessage: 'Analytics loaded',
    );
  }
}
