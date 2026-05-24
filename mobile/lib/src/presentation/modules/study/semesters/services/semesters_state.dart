part of 'semesters_cubit.dart';

sealed class SemestersState extends Equatable {
  const SemestersState();

  @override
  List<Object?> get props => const [];
}

class SemestersInitial extends SemestersState {
  const SemestersInitial();
}

class SemestersLoading extends SemestersState {
  const SemestersLoading();
}

class SemestersLoaded extends SemestersState {
  const SemestersLoaded({
    required this.semesters,
    this.activeSemesterId,
    this.mutating = false,
    this.mutationError,
  });

  final List<Semester> semesters;
  final String? activeSemesterId;
  final bool mutating;
  final String? mutationError;

  Semester? get activeSemester {
    if (activeSemesterId == null) return null;
    for (final s in semesters) {
      if (s.id == activeSemesterId) return s;
    }
    return null;
  }

  List<Semester> get pastTerms => semesters
      .where((s) => s.id != activeSemesterId)
      .toList()
    ..sort((a, b) => b.startDate.compareTo(a.startDate));

  SemestersLoaded copyWith({
    List<Semester>? semesters,
    String? activeSemesterId,
    bool? mutating,
    String? mutationError,
    bool clearActive = false,
    bool clearError = false,
  }) {
    return SemestersLoaded(
      semesters: semesters ?? this.semesters,
      activeSemesterId: clearActive
          ? null
          : (activeSemesterId ?? this.activeSemesterId),
      mutating: mutating ?? this.mutating,
      mutationError: clearError ? null : (mutationError ?? this.mutationError),
    );
  }

  @override
  List<Object?> get props =>
      [semesters, activeSemesterId, mutating, mutationError];
}

class SemestersError extends SemestersState {
  const SemestersError({required this.errorMessage});

  final String errorMessage;

  @override
  List<Object?> get props => [errorMessage];
}
