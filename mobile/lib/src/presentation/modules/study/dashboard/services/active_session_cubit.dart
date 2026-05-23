import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:study_time_tracker/core/utils/core_utils.dart';
import 'package:study_time_tracker/src/domain/models/session/session_payload.dart';
import 'package:study_time_tracker/src/domain/models/session/study_session.dart';
import 'package:study_time_tracker/src/domain/repositories/session_repository_intf.dart';

part 'active_session_state.dart';

/// Owns the dashboard's active-session lifecycle. Wall-clock model (ADR-0003):
/// elapsed is derived from server-issued `startTime` and `accumulatedPauseTime`
/// on every render — never stored as a counter — so backgrounding the app
/// and returning never drifts.
class ActiveSessionCubit extends Cubit<ActiveSessionState> {
  ActiveSessionCubit({required this.sessionRepository})
      : super(const ActiveSessionInitial());

  final ISessionRepository sessionRepository;

  Future<void> checkActive() async {
    try {
      emit(const ActiveSessionChecking());
      final active = await sessionRepository.getActive();
      final today = await _computeTodayTotals();
      final session = active.data;
      if (session == null) {
        emit(ActiveSessionIdle(
          todaySeconds: today.seconds,
          todaySubjectCount: today.subjectCount,
        ));
        return;
      }
      emit(_runningOrPaused(session, today));
    } catch (e) {
      emit(ActiveSessionError(errorMessage: CoreUtils.getErrorMessage(e)));
    }
  }

  Future<void> start({required String subjectId, String? semesterId}) async {
    final prev = state;
    if (prev is! ActiveSessionIdle) return;
    try {
      emit(prev.copyWith(mutating: true));
      final response = await sessionRepository.start(
        payload: StartSessionPayload(
          subjectId: subjectId,
          semesterId: semesterId,
        ),
      );
      final session = response.data;
      if (session == null) {
        emit(prev.copyWith(
          mutating: false,
          mutationError: response.message,
        ));
        return;
      }
      emit(_runningOrPaused(
        session,
        _TodayTotals(prev.todaySeconds, prev.todaySubjectCount),
      ));
    } catch (e) {
      emit(prev.copyWith(
        mutating: false,
        mutationError: CoreUtils.getErrorMessage(e),
      ));
    }
  }

  Future<void> pause() async {
    final prev = state;
    if (prev is! ActiveSessionRunning) return;
    try {
      emit(prev.copyWith(mutating: true));
      final response = await sessionRepository.pause(id: prev.session.id);
      final session = response.data;
      if (session == null) {
        emit(prev.copyWith(
          mutating: false,
          mutationError: response.message,
        ));
        return;
      }
      emit(_runningOrPaused(
        session,
        _TodayTotals(prev.todaySeconds, prev.todaySubjectCount),
      ));
    } catch (e) {
      emit(prev.copyWith(
        mutating: false,
        mutationError: CoreUtils.getErrorMessage(e),
      ));
    }
  }

  Future<void> resume() async {
    final prev = state;
    if (prev is! ActiveSessionPaused) return;
    try {
      emit(prev.copyWith(mutating: true));
      final response = await sessionRepository.resume(id: prev.session.id);
      final session = response.data;
      if (session == null) {
        emit(prev.copyWith(
          mutating: false,
          mutationError: response.message,
        ));
        return;
      }
      emit(_runningOrPaused(
        session,
        _TodayTotals(prev.todaySeconds, prev.todaySubjectCount),
      ));
    } catch (e) {
      emit(prev.copyWith(
        mutating: false,
        mutationError: CoreUtils.getErrorMessage(e),
      ));
    }
  }

  Future<StudySession?> stop() async {
    final prev = state;
    if (prev is! ActiveSessionRunning && prev is! ActiveSessionPaused) {
      return null;
    }
    final id = (prev is ActiveSessionRunning)
        ? prev.session.id
        : (prev as ActiveSessionPaused).session.id;
    try {
      // Emit a mutating clone of whichever state we're in.
      if (prev is ActiveSessionRunning) {
        emit(prev.copyWith(mutating: true));
      } else if (prev is ActiveSessionPaused) {
        emit(prev.copyWith(mutating: true));
      }
      final response = await sessionRepository.stop(id: id);
      final completed = response.data;
      // Recompute today's totals so the just-finished session is included.
      final today = await _computeTodayTotals();
      emit(ActiveSessionIdle(
        todaySeconds: today.seconds,
        todaySubjectCount: today.subjectCount,
      ));
      return completed;
    } catch (e) {
      if (prev is ActiveSessionRunning) {
        emit(prev.copyWith(
          mutating: false,
          mutationError: CoreUtils.getErrorMessage(e),
        ));
      } else if (prev is ActiveSessionPaused) {
        emit(prev.copyWith(
          mutating: false,
          mutationError: CoreUtils.getErrorMessage(e),
        ));
      }
      return null;
    }
  }

  ActiveSessionState _runningOrPaused(
    StudySession session,
    _TodayTotals today,
  ) {
    return switch (session.status) {
      SessionStatus.active => ActiveSessionRunning(
          session: session,
          todaySeconds: today.seconds,
          todaySubjectCount: today.subjectCount,
        ),
      SessionStatus.paused => ActiveSessionPaused(
          session: session,
          todaySeconds: today.seconds,
          todaySubjectCount: today.subjectCount,
        ),
      SessionStatus.completed => ActiveSessionIdle(
          todaySeconds: today.seconds,
          todaySubjectCount: today.subjectCount,
        ),
    };
  }

  Future<_TodayTotals> _computeTodayTotals() async {
    final response = await sessionRepository.getAll();
    if (!response.success) return const _TodayTotals(0, 0);
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    var total = 0;
    final subjects = <String>{};
    for (final s in response.data) {
      if (s.status != SessionStatus.completed) continue;
      if (s.startTime.isBefore(startOfDay)) continue;
      total += s.effectiveStudyTime ?? 0;
      subjects.add(s.subjectId);
    }
    return _TodayTotals(total, subjects.length);
  }
}

class _TodayTotals {
  const _TodayTotals(this.seconds, this.subjectCount);

  final int seconds;
  final int subjectCount;
}
