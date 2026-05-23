import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:study_time_tracker/core/utils/core_utils.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester_payload.dart';
import 'package:study_time_tracker/src/domain/models/subject/subject.dart';
import 'package:study_time_tracker/src/domain/models/subject/subject_payload.dart';
import 'package:study_time_tracker/src/domain/repositories/semester_repository_intf.dart';
import 'package:study_time_tracker/src/domain/repositories/subject_repository_intf.dart';

part 'subjects_state.dart';

class SubjectsCubit extends Cubit<SubjectsState> {
  SubjectsCubit({
    required this.subjectRepository,
    required this.semesterRepository,
  }) : super(const SubjectsInitial());

  final ISubjectRepository subjectRepository;
  final ISemesterRepository semesterRepository;

  Future<void> load() async {
    try {
      emit(const SubjectsLoading());
      final semesters = await semesterRepository.getAll();
      if (!semesters.success || semesters.data.isEmpty) {
        emit(const SubjectsNoSemesters());
        return;
      }
      final activeId = semesters.data
          .firstWhere(
            (s) => s.isActive,
            orElse: () => semesters.data.first,
          )
          .id;
      final subjects = await subjectRepository.getAll();
      emit(SubjectsLoaded(
        subjects: subjects.data,
        semesters: semesters.data,
        activeSemesterId: activeId,
      ));
    } catch (e) {
      emit(SubjectsError(errorMessage: CoreUtils.getErrorMessage(e)));
    }
  }

  Future<void> createSemester({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      emit(const SubjectsLoading());
      await semesterRepository.create(
        payload: SemesterCreatePayload(
          name: name,
          startDate: startDate,
          endDate: endDate,
        ),
      );
      await load();
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
        emit(current.copyWith(
          mutationError: response.message,
        ));
        return false;
      }
      emit(current.copyWith(
        subjects: [...current.subjects, response.data!],
        mutationError: null,
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
      final response = await subjectRepository.update(
        id: id,
        payload: payload,
      );
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
        mutationError: null,
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
        mutationError: null,
      ));
      return true;
    } catch (e) {
      emit(current.copyWith(mutationError: CoreUtils.getErrorMessage(e)));
      return false;
    }
  }
}
