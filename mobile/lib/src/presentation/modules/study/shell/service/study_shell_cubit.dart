import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'study_shell_state.dart';

class StudyShellCubit extends Cubit<StudyShellState> {
  StudyShellCubit() : super(const StudyShellState(currentIndex: 0));

  void selectTab(int index) => emit(StudyShellState(currentIndex: index));
}
