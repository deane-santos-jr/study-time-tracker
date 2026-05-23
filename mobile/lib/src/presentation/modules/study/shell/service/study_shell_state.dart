part of 'study_shell_cubit.dart';

class StudyShellState extends Equatable {
  const StudyShellState({required this.currentIndex});

  final int currentIndex;

  @override
  List<Object> get props => [currentIndex];
}
