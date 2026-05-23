import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:study_time_tracker/core/api/api_response.dart';
import 'package:study_time_tracker/src/domain/models/session/session_payload.dart';
import 'package:study_time_tracker/src/domain/models/session/study_session.dart';
import 'package:study_time_tracker/src/domain/repositories/session_repository_intf.dart';
import 'package:study_time_tracker/src/presentation/modules/study/dashboard/services/active_session_cubit.dart';

class _MockSessionRepository extends Mock implements ISessionRepository {}

class _FakePayload extends Fake implements StartSessionPayload {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakePayload());
  });

  late _MockSessionRepository repo;
  final start = DateTime(2026, 5, 24, 10);

  StudySession sessionWith({
    required SessionStatus status,
    DateTime? startTime,
    DateTime? pausedAt,
    int accumulatedPauseTime = 0,
    int? effectiveStudyTime,
    DateTime? endTime,
  }) {
    return StudySession(
      id: 'sess-1',
      subjectId: 'subj-1',
      startTime: startTime ?? start,
      pausedAt: pausedAt,
      status: status,
      accumulatedPauseTime: accumulatedPauseTime,
      breakCount: 0,
      effectiveStudyTime: effectiveStudyTime,
      endTime: endTime,
    );
  }

  setUp(() {
    repo = _MockSessionRepository();
    when(() => repo.getAll()).thenAnswer(
      (_) async => APIListResponse<StudySession>(
        success: true,
        message: 'ok',
        statusCode: 200,
        data: const [],
      ),
    );
  });

  group('checkActive', () {
    blocTest<ActiveSessionCubit, ActiveSessionState>(
      'emits Checking then Idle when no active session',
      build: () {
        when(() => repo.getActive()).thenAnswer(
          (_) async => APIResponse<StudySession?>(
            success: true,
            message: 'ok',
            statusCode: 200,
            data: null,
          ),
        );
        return ActiveSessionCubit(sessionRepository: repo);
      },
      act: (c) => c.checkActive(),
      expect: () => [
        isA<ActiveSessionChecking>(),
        isA<ActiveSessionIdle>(),
      ],
    );

    blocTest<ActiveSessionCubit, ActiveSessionState>(
      'emits Checking then Running when server has active session',
      build: () {
        when(() => repo.getActive()).thenAnswer(
          (_) async => APIResponse<StudySession?>(
            success: true,
            message: 'ok',
            statusCode: 200,
            data: sessionWith(status: SessionStatus.active),
          ),
        );
        return ActiveSessionCubit(sessionRepository: repo);
      },
      act: (c) => c.checkActive(),
      expect: () => [
        isA<ActiveSessionChecking>(),
        isA<ActiveSessionRunning>(),
      ],
    );

    blocTest<ActiveSessionCubit, ActiveSessionState>(
      'emits Paused when server has paused session',
      build: () {
        when(() => repo.getActive()).thenAnswer(
          (_) async => APIResponse<StudySession?>(
            success: true,
            message: 'ok',
            statusCode: 200,
            data: sessionWith(
              status: SessionStatus.paused,
              pausedAt: start.add(const Duration(minutes: 10)),
            ),
          ),
        );
        return ActiveSessionCubit(sessionRepository: repo);
      },
      act: (c) => c.checkActive(),
      expect: () => [
        isA<ActiveSessionChecking>(),
        isA<ActiveSessionPaused>(),
      ],
    );
  });

  group('start / pause / resume / stop', () {
    blocTest<ActiveSessionCubit, ActiveSessionState>(
      'start emits mutating Idle then Running',
      build: () {
        when(() => repo.getActive()).thenAnswer(
          (_) async => APIResponse<StudySession?>(
            success: true,
            message: 'ok',
            statusCode: 200,
            data: null,
          ),
        );
        when(() => repo.start(payload: any(named: 'payload'))).thenAnswer(
          (_) async => APIResponse<StudySession>(
            success: true,
            message: 'ok',
            statusCode: 201,
            data: sessionWith(status: SessionStatus.active),
          ),
        );
        return ActiveSessionCubit(sessionRepository: repo);
      },
      seed: () => const ActiveSessionIdle(),
      act: (c) => c.start(subjectId: 'subj-1'),
      expect: () => [
        isA<ActiveSessionIdle>().having((s) => s.mutating, 'mutating', true),
        isA<ActiveSessionRunning>(),
      ],
    );

    blocTest<ActiveSessionCubit, ActiveSessionState>(
      'pause emits Running->Paused',
      build: () {
        when(() => repo.pause(id: any(named: 'id'))).thenAnswer(
          (_) async => APIResponse<StudySession>(
            success: true,
            message: 'ok',
            statusCode: 200,
            data: sessionWith(
              status: SessionStatus.paused,
              pausedAt: start.add(const Duration(minutes: 5)),
            ),
          ),
        );
        return ActiveSessionCubit(sessionRepository: repo);
      },
      seed: () => ActiveSessionRunning(
        session: sessionWith(status: SessionStatus.active),
      ),
      act: (c) => c.pause(),
      expect: () => [
        isA<ActiveSessionRunning>().having((s) => s.mutating, 'mutating', true),
        isA<ActiveSessionPaused>(),
      ],
    );

    blocTest<ActiveSessionCubit, ActiveSessionState>(
      'resume emits Paused->Running',
      build: () {
        when(() => repo.resume(id: any(named: 'id'))).thenAnswer(
          (_) async => APIResponse<StudySession>(
            success: true,
            message: 'ok',
            statusCode: 200,
            data: sessionWith(
              status: SessionStatus.active,
              accumulatedPauseTime: 120,
            ),
          ),
        );
        return ActiveSessionCubit(sessionRepository: repo);
      },
      seed: () => ActiveSessionPaused(
        session: sessionWith(
          status: SessionStatus.paused,
          pausedAt: start.add(const Duration(minutes: 5)),
        ),
      ),
      act: (c) => c.resume(),
      expect: () => [
        isA<ActiveSessionPaused>().having((s) => s.mutating, 'mutating', true),
        isA<ActiveSessionRunning>(),
      ],
    );

    blocTest<ActiveSessionCubit, ActiveSessionState>(
      'stop emits mutating Running then Idle',
      build: () {
        when(() => repo.stop(id: any(named: 'id'))).thenAnswer(
          (_) async => APIResponse<StudySession>(
            success: true,
            message: 'ok',
            statusCode: 200,
            data: sessionWith(
              status: SessionStatus.completed,
              effectiveStudyTime: 1800,
              endTime: start.add(const Duration(minutes: 30)),
            ),
          ),
        );
        return ActiveSessionCubit(sessionRepository: repo);
      },
      seed: () => ActiveSessionRunning(
        session: sessionWith(status: SessionStatus.active),
      ),
      act: (c) => c.stop(),
      expect: () => [
        isA<ActiveSessionRunning>().having((s) => s.mutating, 'mutating', true),
        isA<ActiveSessionIdle>(),
      ],
    );
  });

  group('wall-clock derived elapsed', () {
    test('active session ticks from startTime ignoring accumulatedPauseTime',
        () {
      final session = sessionWith(
        status: SessionStatus.active,
        startTime: start,
        accumulatedPauseTime: 30,
      );
      final at = start.add(const Duration(seconds: 100));
      // 100s elapsed, minus 30s accumulated paused = 70s effective.
      expect(session.effectiveElapsedAt(at), 70);
    });

    test('paused session freezes at pausedAt', () {
      final pausedAt = start.add(const Duration(seconds: 200));
      final session = sessionWith(
        status: SessionStatus.paused,
        startTime: start,
        pausedAt: pausedAt,
        accumulatedPauseTime: 50,
      );
      final farFuture = start.add(const Duration(hours: 5));
      // Reference is pausedAt regardless of how long ago it happened.
      // (200 - 50) = 150s effective.
      expect(session.effectiveElapsedAt(farFuture), 150);
    });

    test('completed session uses endTime as the reference', () {
      final endTime = start.add(const Duration(seconds: 600));
      final session = sessionWith(
        status: SessionStatus.completed,
        startTime: start,
        endTime: endTime,
        accumulatedPauseTime: 100,
      );
      expect(
        session.effectiveElapsedAt(DateTime.now()),
        500,
      );
    });
  });
}
