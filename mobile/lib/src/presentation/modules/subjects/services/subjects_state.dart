part of 'subjects_cubit.dart';

sealed class SubjectsState extends Equatable {
  const SubjectsState();

  @override
  List<Object?> get props => const [];
}

class SubjectsInitial extends SubjectsState {
  const SubjectsInitial();
}

class SubjectsLoading extends SubjectsState {
  const SubjectsLoading();
}

class SubjectsLoaded extends SubjectsState {
  const SubjectsLoaded({
    required this.subjects,
    required this.semesterId,
    this.mutationError,
  });

  /// Subjects belonging to the semester filter applied by the cubit. When
  /// `semesterId` is null (no active semester), this list is empty by design
  /// — subjects require a semester so a fresh user has none.
  final List<Subject> subjects;

  /// The semester filter applied to produce this list. Null when no semester
  /// is active (and therefore no subjects can exist yet).
  final String? semesterId;

  final String? mutationError;

  SubjectsLoaded copyWith({
    List<Subject>? subjects,
    String? semesterId,
    String? mutationError,
    bool clearError = false,
  }) {
    return SubjectsLoaded(
      subjects: subjects ?? this.subjects,
      semesterId: semesterId ?? this.semesterId,
      mutationError: clearError ? null : (mutationError ?? this.mutationError),
    );
  }

  @override
  List<Object?> get props => [subjects, semesterId, mutationError];
}

class SubjectsError extends SubjectsState {
  const SubjectsError({required this.errorMessage});

  final String errorMessage;

  @override
  List<Object?> get props => [errorMessage];
}
