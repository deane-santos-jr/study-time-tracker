import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:study_time_tracker/core/utils/core_utils.dart';
import 'package:study_time_tracker/src/domain/models/subject/subject.dart';
import 'package:study_time_tracker/src/domain/models/subject/subject_payload.dart';
import 'package:study_time_tracker/src/domain/repositories/subject_repository_intf.dart';

part 'subjects_state.dart';

class SubjectsCubit extends Cubit<SubjectsState> {
  SubjectsCubit({required this.subjectRepository})
      : super(const SubjectsInitial());

  final ISubjectRepository subjectRepository;

  /// Load every subject the user owns, across all semesters. The subjects
  /// screen is a global manager — semester scoping happens at consumer sites
  /// (e.g. the dashboard picker filters by the active semester).
  Future<void> load() async {
    try {
      emit(const SubjectsLoading());
      final response = await subjectRepository.getAll();
      emit(SubjectsLoaded(subjects: response.data));
    } catch (e) {
      emit(SubjectsError(errorMessage: CoreUtils.getErrorMessage(e)));
    }
  }

  Future<bool> createSubject({required SubjectCreatePayload payload}) async {
    final current = state;
    if (current is! SubjectsLoaded) return false;
    try {
      final response = await subjectRepository.create(payload: payload);
      if (!response.success || response.data == null) {
        emit(current.copyWith(mutationError: response.message));
        return false;
      }
      emit(current.copyWith(
        subjects: [...current.subjects, response.data!],
        clearError: true,
      ));
      return true;
    } catch (e) {
      emit(current.copyWith(mutationError: CoreUtils.getErrorMessage(e)));
      return false;
    }
  }

  Future<bool> updateSubject({
    required String id,
    required SubjectUpdatePayload payload,
  }) async {
    final current = state;
    if (current is! SubjectsLoaded) return false;
    try {
      final response = await subjectRepository.update(id: id, payload: payload);
      if (!response.success || response.data == null) {
        emit(current.copyWith(mutationError: response.message));
        return false;
      }
      final next = response.data!;
      emit(current.copyWith(
        subjects: [
          for (final s in current.subjects)
            if (s.id == id) next else s,
        ],
        clearError: true,
      ));
      return true;
    } catch (e) {
      emit(current.copyWith(mutationError: CoreUtils.getErrorMessage(e)));
      return false;
    }
  }

  Future<bool> deleteSubject({required String id}) async {
    final current = state;
    if (current is! SubjectsLoaded) return false;
    try {
      final response = await subjectRepository.delete(id: id);
      if (!response.success) {
        emit(current.copyWith(mutationError: response.message));
        return false;
      }
      emit(current.copyWith(
        subjects: current.subjects.where((s) => s.id != id).toList(),
        clearError: true,
      ));
      return true;
    } catch (e) {
      emit(current.copyWith(mutationError: CoreUtils.getErrorMessage(e)));
      return false;
    }
  }
}
