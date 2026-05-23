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

class SubjectsNoSemesters extends SubjectsState {
  const SubjectsNoSemesters();
}

class SubjectsLoaded extends SubjectsState {
  const SubjectsLoaded({
    required this.subjects,
    required this.semesters,
    required this.activeSemesterId,
    this.mutationError,
  });

  final List<Subject> subjects;
  final List<Semester> semesters;
  final String activeSemesterId;
  final String? mutationError;

  SubjectsLoaded copyWith({
    List<Subject>? subjects,
    List<Semester>? semesters,
    String? activeSemesterId,
    String? mutationError,
  }) {
    return SubjectsLoaded(
      subjects: subjects ?? this.subjects,
      semesters: semesters ?? this.semesters,
      activeSemesterId: activeSemesterId ?? this.activeSemesterId,
      mutationError: mutationError,
    );
  }

  Semester? semesterFor(String id) {
    for (final s in semesters) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  List<Object?> get props =>
      [subjects, semesters, activeSemesterId, mutationError];
}

class SubjectsError extends SubjectsState {
  const SubjectsError({required this.errorMessage});

  final String errorMessage;

  @override
  List<Object?> get props => [errorMessage];
}
