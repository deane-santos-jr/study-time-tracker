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
    this.mutationError,
  });

  /// Every subject the user owns across all semesters. Consumers that want
  /// "subjects in the active semester" (e.g. the dashboard picker) filter
  /// this list themselves against `SemestersCubit.activeSemesterId`.
  final List<Subject> subjects;

  final String? mutationError;

  SubjectsLoaded copyWith({
    List<Subject>? subjects,
    String? mutationError,
    bool clearError = false,
  }) {
    return SubjectsLoaded(
      subjects: subjects ?? this.subjects,
      mutationError: clearError ? null : (mutationError ?? this.mutationError),
    );
  }

  @override
  List<Object?> get props => [subjects, mutationError];
}

class SubjectsError extends SubjectsState {
  const SubjectsError({required this.errorMessage});

  final String errorMessage;

  @override
  List<Object?> get props => [errorMessage];
}
