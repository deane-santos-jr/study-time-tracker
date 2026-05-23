/// Backend analytics digest, plus a small streak helper.
///
/// Date strings from the backend are UTC-day buckets (`new Date().toISOString()
/// .split('T')[0]` server-side), so streak math is done in UTC to match the
/// same bucketing. A future cleanup could move to per-user-timezone buckets.
class AnalyticsSummary {
  AnalyticsSummary({
    required this.totalEffectiveTime,
    required this.totalSessions,
    required this.longestEffectiveSession,
    required this.dailyStats,
    required this.subjectStats,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    final rawDaily = (json['dailyStats'] as List<dynamic>?) ?? const [];
    final rawSubject = (json['subjectStats'] as List<dynamic>?) ?? const [];
    return AnalyticsSummary(
      totalEffectiveTime: (json['totalEffectiveTime'] as num?)?.toInt() ?? 0,
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
      longestEffectiveSession:
          (json['longestEffectiveSession'] as num?)?.toInt() ?? 0,
      dailyStats: rawDaily
          .whereType<Map<String, dynamic>>()
          .map(DailyStat.fromJson)
          .toList(),
      subjectStats: rawSubject
          .whereType<Map<String, dynamic>>()
          .map(SubjectStat.fromJson)
          .toList(),
    );
  }

  final int totalEffectiveTime;
  final int totalSessions;
  final int longestEffectiveSession;
  final List<DailyStat> dailyStats;
  final List<SubjectStat> subjectStats;

  /// Sum of `dailyStats` totals from the rolling N-day window ending today
  /// (inclusive, UTC). Matches the bucketing the backend already uses.
  int windowTotal(DateTime now, {int days = 7}) {
    if (dailyStats.isEmpty) return 0;
    final utcNow = now.toUtc();
    final endKey = DateTime.utc(utcNow.year, utcNow.month, utcNow.day);
    final startKey = endKey.subtract(Duration(days: days - 1));
    var total = 0;
    for (final stat in dailyStats) {
      final key = stat.date.toUtc();
      if (!key.isBefore(startKey) && !key.isAfter(endKey)) {
        total += stat.totalTime;
      }
    }
    return total;
  }

  /// Best historical N-day rolling window total in `dailyStats` (UTC buckets).
  /// Used to phrase the "X% under your best" comparison on the home tile.
  /// Returns 0 when there isn't enough history to compute.
  int bestRollingWindow({int days = 7}) {
    if (dailyStats.length < days) return 0;
    final sorted = [...dailyStats]
      ..sort((a, b) => a.date.compareTo(b.date));
    var best = 0;
    var sum = 0;
    for (var i = 0; i < sorted.length; i++) {
      sum += sorted[i].totalTime;
      if (i >= days) sum -= sorted[i - days].totalTime;
      if (i >= days - 1 && sum > best) best = sum;
    }
    return best;
  }

  /// Consecutive days ending at the most recent day with study time > 0.
  /// If today has activity, today is included; otherwise the chain ends
  /// at yesterday (a fresh day doesn't break a streak until midnight passes
  /// without studying).
  int computeStreak(DateTime now) {
    if (dailyStats.isEmpty) return 0;

    final activeDays = <String>{};
    for (final stat in dailyStats) {
      if (stat.totalTime > 0) {
        activeDays.add(_utcKey(stat.date));
      }
    }
    if (activeDays.isEmpty) return 0;

    final utcNow = now.toUtc();
    var cursor = DateTime.utc(utcNow.year, utcNow.month, utcNow.day);
    if (!activeDays.contains(_utcKey(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!activeDays.contains(_utcKey(cursor))) return 0;
    }

    var streak = 0;
    while (activeDays.contains(_utcKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static String _utcKey(DateTime d) {
    final utc = d.toUtc();
    final y = utc.year.toString().padLeft(4, '0');
    final m = utc.month.toString().padLeft(2, '0');
    final day = utc.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}

class SubjectStat {
  SubjectStat({
    required this.subjectId,
    required this.subjectName,
    required this.totalTime,
    required this.sessionCount,
  });

  factory SubjectStat.fromJson(Map<String, dynamic> json) => SubjectStat(
        subjectId: json['subjectId'] as String,
        subjectName: json['subjectName'] as String? ?? '',
        totalTime: (json['totalTime'] as num?)?.toInt() ?? 0,
        sessionCount: (json['sessionCount'] as num?)?.toInt() ?? 0,
      );

  final String subjectId;
  final String subjectName;
  final int totalTime;
  final int sessionCount;
}

class DailyStat {
  DailyStat({
    required this.date,
    required this.totalTime,
    required this.sessionCount,
  });

  factory DailyStat.fromJson(Map<String, dynamic> json) {
    // Backend emits `YYYY-MM-DD` from `new Date().toISOString().split('T')[0]`,
    // which is the UTC date. Parse as UTC midnight to preserve that bucketing —
    // a bare `DateTime.parse('2026-05-23')` would be interpreted as local time
    // and slide by a day in non-UTC zones.
    final dateStr = json['date'] as String;
    return DailyStat(
      date: DateTime.parse('${dateStr}T00:00:00Z'),
      totalTime: (json['totalTime'] as num?)?.toInt() ?? 0,
      sessionCount: (json['sessionCount'] as num?)?.toInt() ?? 0,
    );
  }

  final DateTime date;
  final int totalTime;
  final int sessionCount;
}
