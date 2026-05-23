import 'package:flutter_test/flutter_test.dart';
import 'package:study_time_tracker/src/domain/models/analytics/analytics_summary.dart';

void main() {
  DailyStat day(String iso, int seconds) => DailyStat(
        // Match the production parse: backend date strings are UTC-day keys.
        date: DateTime.parse('${iso}T00:00:00Z'),
        totalTime: seconds,
        sessionCount: seconds > 0 ? 1 : 0,
      );

  AnalyticsSummary summary(List<DailyStat> days) => AnalyticsSummary(
        totalEffectiveTime: 0,
        totalSessions: 0,
        longestEffectiveSession: 0,
        dailyStats: days,
        subjectStats: const [],
      );

  group('AnalyticsSummary.computeStreak', () {
    // Streak math runs in UTC to match backend date bucketing.
    final now = DateTime.utc(2026, 5, 24, 14, 0); // Sun

    test('empty stats => 0', () {
      expect(summary(const []).computeStreak(now), 0);
    });

    test('only zero-time days => 0', () {
      expect(
        summary([day('2026-05-23', 0), day('2026-05-24', 0)])
            .computeStreak(now),
        0,
      );
    });

    test('today only => 1', () {
      expect(summary([day('2026-05-24', 1200)]).computeStreak(now), 1);
    });

    test('today + yesterday => 2', () {
      expect(
        summary([day('2026-05-23', 600), day('2026-05-24', 1200)])
            .computeStreak(now),
        2,
      );
    });

    test('yesterday only, today empty => 1 (does not break until tomorrow)',
        () {
      expect(summary([day('2026-05-23', 600)]).computeStreak(now), 1);
    });

    test('gap breaks the streak', () {
      // studied 5/20, 5/21, then skipped 5/22, then 5/23 + today
      // streak counts back from today through 5/23, breaks at 5/22
      expect(
        summary([
          day('2026-05-20', 600),
          day('2026-05-21', 600),
          day('2026-05-23', 600),
          day('2026-05-24', 1200),
        ]).computeStreak(now),
        2,
      );
    });

    test('today empty and yesterday empty => 0 even if older days exist', () {
      expect(
        summary([day('2026-05-20', 600), day('2026-05-21', 600)])
            .computeStreak(now),
        0,
      );
    });
  });

  group('AnalyticsSummary.windowTotal', () {
    final now = DateTime.utc(2026, 5, 24, 14, 0);

    test('empty => 0', () {
      expect(summary(const []).windowTotal(now), 0);
    });

    test('sums last 7 days, inclusive of today', () {
      // 7-day window ending 2026-05-24 is 5/18..5/24 (inclusive)
      final s = summary([
        day('2026-05-17', 1000), // out of window
        day('2026-05-18', 600),
        day('2026-05-22', 1200),
        day('2026-05-24', 900),
      ]);
      expect(s.windowTotal(now), 600 + 1200 + 900);
    });
  });

  group('AnalyticsSummary.bestRollingWindow', () {
    test('returns 0 when fewer than `days` daily buckets exist', () {
      final s = summary([day('2026-05-23', 600), day('2026-05-24', 600)]);
      expect(s.bestRollingWindow(), 0);
    });

    test('finds the best 7-day sliding window', () {
      final s = summary(List<DailyStat>.generate(
        10,
        (i) {
          final day = (i + 1).toString().padLeft(2, '0');
          // tall spike in the middle so the best window straddles it
          final t = i == 4 ? 7200 : 600;
          return DailyStat(
            date: DateTime.parse('2026-05-${day}T00:00:00Z'),
            totalTime: t,
            sessionCount: 1,
          );
        },
      ));
      // window 5/01..5/07 = 6*600 + 7200 = 10800; window 5/04..5/10 = same.
      expect(s.bestRollingWindow(), 10800);
    });
  });
}
