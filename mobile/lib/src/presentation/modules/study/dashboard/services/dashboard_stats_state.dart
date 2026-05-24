part of 'dashboard_stats_cubit.dart';

sealed class DashboardStatsState extends Equatable {
  const DashboardStatsState();

  @override
  List<Object?> get props => const [];
}

class DashboardStatsInitial extends DashboardStatsState {
  const DashboardStatsInitial();
}

class DashboardStatsLoading extends DashboardStatsState {
  const DashboardStatsLoading();
}

class DashboardStatsLoaded extends DashboardStatsState {
  const DashboardStatsLoaded({
    required this.streakDays,
    required this.longestSessionSeconds,
    required this.totalSessions,
    required this.subjectStats,
    required this.windowSeconds,
    required this.bestWindowSeconds,
    required this.adHocSeconds,
  });

  final int streakDays;
  final int longestSessionSeconds;
  final int totalSessions;
  final List<SubjectStat> subjectStats;
  final int windowSeconds;
  final int bestWindowSeconds;

  /// Total effective study time (last 7 days) of completed sessions with no
  /// subjectId — i.e. ad-hoc activities. Drives the "other" aggregate row in
  /// the dashboard's subject totals list.
  final int adHocSeconds;

  @override
  List<Object?> get props => [
        streakDays,
        longestSessionSeconds,
        totalSessions,
        subjectStats,
        windowSeconds,
        bestWindowSeconds,
        adHocSeconds,
      ];
}

class DashboardStatsError extends DashboardStatsState {
  const DashboardStatsError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
