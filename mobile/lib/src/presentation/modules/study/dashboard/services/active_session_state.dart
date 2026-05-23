part of 'active_session_cubit.dart';

sealed class ActiveSessionState extends Equatable {
  const ActiveSessionState();

  @override
  List<Object?> get props => const [];
}

class ActiveSessionInitial extends ActiveSessionState {
  const ActiveSessionInitial();
}

class ActiveSessionChecking extends ActiveSessionState {
  const ActiveSessionChecking();
}

class ActiveSessionIdle extends ActiveSessionState {
  const ActiveSessionIdle({
    this.todaySeconds = 0,
    this.todaySubjectCount = 0,
    this.mutating = false,
    this.mutationError,
  });

  final int todaySeconds;
  final int todaySubjectCount;
  final bool mutating;
  final String? mutationError;

  ActiveSessionIdle copyWith({
    int? todaySeconds,
    int? todaySubjectCount,
    bool? mutating,
    String? mutationError,
  }) {
    return ActiveSessionIdle(
      todaySeconds: todaySeconds ?? this.todaySeconds,
      todaySubjectCount: todaySubjectCount ?? this.todaySubjectCount,
      mutating: mutating ?? this.mutating,
      mutationError: mutationError,
    );
  }

  @override
  List<Object?> get props =>
      [todaySeconds, todaySubjectCount, mutating, mutationError];
}

class ActiveSessionRunning extends ActiveSessionState {
  const ActiveSessionRunning({
    required this.session,
    this.todaySeconds = 0,
    this.todaySubjectCount = 0,
    this.mutating = false,
    this.mutationError,
  });

  final StudySession session;
  final int todaySeconds;
  final int todaySubjectCount;
  final bool mutating;
  final String? mutationError;

  ActiveSessionRunning copyWith({
    StudySession? session,
    int? todaySeconds,
    int? todaySubjectCount,
    bool? mutating,
    String? mutationError,
  }) {
    return ActiveSessionRunning(
      session: session ?? this.session,
      todaySeconds: todaySeconds ?? this.todaySeconds,
      todaySubjectCount: todaySubjectCount ?? this.todaySubjectCount,
      mutating: mutating ?? this.mutating,
      mutationError: mutationError,
    );
  }

  @override
  List<Object?> get props => [
        session.id,
        session.status,
        session.startTime,
        todaySeconds,
        todaySubjectCount,
        mutating,
        mutationError,
      ];
}

class ActiveSessionPaused extends ActiveSessionState {
  const ActiveSessionPaused({
    required this.session,
    this.todaySeconds = 0,
    this.todaySubjectCount = 0,
    this.mutating = false,
    this.mutationError,
  });

  final StudySession session;
  final int todaySeconds;
  final int todaySubjectCount;
  final bool mutating;
  final String? mutationError;

  ActiveSessionPaused copyWith({
    StudySession? session,
    int? todaySeconds,
    int? todaySubjectCount,
    bool? mutating,
    String? mutationError,
  }) {
    return ActiveSessionPaused(
      session: session ?? this.session,
      todaySeconds: todaySeconds ?? this.todaySeconds,
      todaySubjectCount: todaySubjectCount ?? this.todaySubjectCount,
      mutating: mutating ?? this.mutating,
      mutationError: mutationError,
    );
  }

  @override
  List<Object?> get props => [
        session.id,
        session.status,
        session.pausedAt,
        todaySeconds,
        todaySubjectCount,
        mutating,
        mutationError,
      ];
}

class ActiveSessionError extends ActiveSessionState {
  const ActiveSessionError({required this.errorMessage});

  final String errorMessage;

  @override
  List<Object?> get props => [errorMessage];
}
