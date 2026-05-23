import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:study_time_tracker/core/utils/core_utils.dart';
import 'package:study_time_tracker/src/domain/models/analytics/analytics_summary.dart';
import 'package:study_time_tracker/src/domain/repositories/analytics_repository_intf.dart';

part 'dashboard_stats_state.dart';

/// Loads the dashboard's at-a-glance stats (streak, longest session,
/// totals) from `/analytics`. Refreshed on dashboard mount and after each
/// session completes so the numbers stay in sync with the day.
class DashboardStatsCubit extends Cubit<DashboardStatsState> {
  DashboardStatsCubit({required this.analyticsRepository})
      : super(const DashboardStatsInitial());

  final IAnalyticsRepository analyticsRepository;

  Future<void> load() async {
    try {
      emit(const DashboardStatsLoading());
      final response = await analyticsRepository.getSummary();
      final summary = response.data;
      if (summary == null) {
        emit(DashboardStatsError(message: response.message));
        return;
      }
      final now = DateTime.now();
      final sortedSubjects = [...summary.subjectStats]
        ..sort((a, b) => b.totalTime.compareTo(a.totalTime));
      emit(DashboardStatsLoaded(
        streakDays: summary.computeStreak(now),
        longestSessionSeconds: summary.longestEffectiveSession,
        totalSessions: summary.totalSessions,
        subjectStats: sortedSubjects,
        windowSeconds: summary.windowTotal(now),
        bestWindowSeconds: summary.bestRollingWindow(),
      ));
    } catch (e) {
      emit(DashboardStatsError(message: CoreUtils.getErrorMessage(e)));
    }
  }
}
