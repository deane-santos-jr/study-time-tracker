import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:study_time_tracker/core/api/api_response.dart';
import 'package:study_time_tracker/src/domain/models/session/study_session.dart';
import 'package:study_time_tracker/src/domain/repositories/session_repository_intf.dart';
import 'package:study_time_tracker/src/presentation/modules/history/services/history_cubit.dart';

class _MockSessionRepository extends Mock implements ISessionRepository {}

StudySession sessionFor({
  required String id,
  required DateTime startTime,
  String? subjectId = 'subj-1',
  String? activityName,
  int? effectiveStudyTime = 0,
  SessionStatus status = SessionStatus.completed,
}) {
  return StudySession(
    id: id,
    subjectId: subjectId,
    activityName: activityName,
    startTime: startTime,
    status: status,
    accumulatedPauseTime: 0,
    breakCount: 0,
    effectiveStudyTime: effectiveStudyTime,
    endTime: status == SessionStatus.completed ? startTime : null,
  );
}

void main() {
  late _MockSessionRepository repo;

  setUp(() {
    repo = _MockSessionRepository();
  });

  blocTest<HistoryCubit, HistoryState>(
    'load() emits Loading then Loaded with sessions sorted newest-first',
    build: () {
      when(() => repo.getAll()).thenAnswer(
        (_) async => APIListResponse<StudySession>(
          success: true,
          message: 'ok',
          statusCode: 200,
          data: [
            sessionFor(id: 'older', startTime: DateTime(2026, 5, 20, 9)),
            sessionFor(id: 'newest', startTime: DateTime(2026, 5, 24, 14)),
            sessionFor(id: 'middle', startTime: DateTime(2026, 5, 22, 11)),
          ],
        ),
      );
      return HistoryCubit(sessionRepository: repo);
    },
    act: (c) => c.load(),
    expect: () => [
      isA<HistoryLoading>(),
      isA<HistoryLoaded>()
          .having((s) => s.sessions.length, 'count', 3)
          .having(
            (s) => s.sessions.map((x) => x.id).toList(),
            'ids',
            ['newest', 'middle', 'older'],
          ),
    ],
  );

  blocTest<HistoryCubit, HistoryState>(
    'load() with empty API result emits Loading then Loaded with empty list',
    build: () {
      when(() => repo.getAll()).thenAnswer(
        (_) async => APIListResponse<StudySession>(
          success: true,
          message: 'ok',
          statusCode: 200,
          data: const [],
        ),
      );
      return HistoryCubit(sessionRepository: repo);
    },
    act: (c) => c.load(),
    expect: () => [
      isA<HistoryLoading>(),
      isA<HistoryLoaded>().having((s) => s.sessions, 'sessions', isEmpty),
    ],
  );

  blocTest<HistoryCubit, HistoryState>(
    'load() preserves ad-hoc sessions in the sorted list',
    build: () {
      when(() => repo.getAll()).thenAnswer(
        (_) async => APIListResponse<StudySession>(
          success: true,
          message: 'ok',
          statusCode: 200,
          data: [
            sessionFor(
              id: 'subj',
              startTime: DateTime(2026, 5, 22),
              subjectId: 'subj-1',
            ),
            sessionFor(
              id: 'adhoc',
              startTime: DateTime(2026, 5, 24),
              subjectId: null,
              activityName: 'reading',
            ),
          ],
        ),
      );
      return HistoryCubit(sessionRepository: repo);
    },
    act: (c) => c.load(),
    expect: () => [
      isA<HistoryLoading>(),
      isA<HistoryLoaded>()
          .having((s) => s.sessions.length, 'count', 2)
          .having(
            (s) => s.sessions.first.activityName,
            'first.activityName',
            'reading',
          )
          .having((s) => s.sessions.first.isAdHoc, 'first.isAdHoc', true),
    ],
  );

  blocTest<HistoryCubit, HistoryState>(
    'load() emits Loading then Error when the repository throws',
    build: () {
      when(() => repo.getAll()).thenThrow(Exception('network down'));
      return HistoryCubit(sessionRepository: repo);
    },
    act: (c) => c.load(),
    expect: () => [
      isA<HistoryLoading>(),
      isA<HistoryError>()
          .having((s) => s.errorMessage, 'errorMessage', isNotEmpty),
    ],
  );
}
