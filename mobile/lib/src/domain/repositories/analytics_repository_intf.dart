import 'package:study_time_tracker/core/api/api_response.dart';
import 'package:study_time_tracker/src/domain/models/analytics/analytics_summary.dart';

abstract class IAnalyticsRepository {
  Future<APIResponse<AnalyticsSummary>> getSummary();
}
