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
  });

  final int streakDays;
  final int longestSessionSeconds;
  final int totalSessions;
  final List<SubjectStat> subjectStats;
  final int windowSeconds;
  final int bestWindowSeconds;

  @override
  List<Object?> get props => [
        streakDays,
        longestSessionSeconds,
        totalSessions,
        subjectStats,
        windowSeconds,
        bestWindowSeconds,
      ];
}

class DashboardStatsError extends DashboardStatsState {
  const DashboardStatsError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
