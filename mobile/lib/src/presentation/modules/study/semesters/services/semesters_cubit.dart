import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:study_time_tracker/core/utils/core_utils.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester_payload.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester_stats.dart';
import 'package:study_time_tracker/src/domain/repositories/semester_repository_intf.dart';

part 'semesters_state.dart';

class SemestersCubit extends Cubit<SemestersState> {
  SemestersCubit({required this.semesterRepository})
      : super(const SemestersInitial());

  final ISemesterRepository semesterRepository;

  Future<void> load() async {
    try {
      emit(const SemestersLoading());
      final response = await semesterRepository.getAll();
      if (!response.success) {
        emit(SemestersError(errorMessage: response.message));
        return;
      }
      final semesters = response.data;
      final active = semesters.where((s) => s.isActive).toList();
      emit(SemestersLoaded(
        semesters: semesters,
        activeSemesterId: active.isEmpty ? null : active.first.id,
      ));
    } catch (e) {
      emit(SemestersError(errorMessage: CoreUtils.getErrorMessage(e)));
    }
  }

  Future<Semester?> create({required SemesterCreatePayload payload}) async {
    final current = state;
    if (current is! SemestersLoaded && current is! SemestersInitial) {
      return null;
    }
    final loaded = current is SemestersLoaded
        ? current
        : const SemestersLoaded(semesters: []);

    emit(loaded.copyWith(mutating: true, clearError: true));
    try {
      final response = await semesterRepository.create(payload: payload);
      if (!response.success || response.data == null) {
        emit(loaded.copyWith(mutating: false, mutationError: response.message));
        return null;
      }
      // Reload from server to pick up the auto-active state if applicable.
      await load();
      return response.data;
    } catch (e) {
      emit(loaded.copyWith(
        mutating: false,
        mutationError: CoreUtils.getErrorMessage(e),
      ));
      return null;
    }
  }

  Future<Semester?> update({
    required String id,
    required SemesterUpdatePayload payload,
  }) async {
    final current = state;
    if (current is! SemestersLoaded) return null;
    emit(current.copyWith(mutating: true, clearError: true));
    try {
      final response = await semesterRepository.update(id: id, payload: payload);
      if (!response.success || response.data == null) {
        emit(current.copyWith(mutating: false, mutationError: response.message));
        return null;
      }
      final updated = response.data!;
      final updatedList = [
        for (final s in current.semesters) if (s.id == id) updated else s,
      ];
      // If isActive flipped, recompute activeSemesterId. The server enforces
      // at-most-one-active per user, so if we just activated one, deactivate
      // the others locally too via reload.
      if (payload.isActive == true) {
        await load();
      } else {
        emit(current.copyWith(
          semesters: updatedList,
          mutating: false,
          activeSemesterId: updated.isActive ? updated.id : current.activeSemesterId,
        ));
      }
      return updated;
    } catch (e) {
      emit(current.copyWith(
        mutating: false,
        mutationError: CoreUtils.getErrorMessage(e),
      ));
      return null;
    }
  }

  Future<bool> activate({required String id}) async {
    final updated = await update(
      id: id,
      payload: SemesterUpdatePayload(isActive: true),
    );
    return updated != null;
  }

  Future<bool> delete({required String id}) async {
    final current = state;
    if (current is! SemestersLoaded) return false;
    if (current.activeSemesterId == id) {
      emit(current.copyWith(
        mutationError: 'Switch active to another term before deleting.',
      ));
      return false;
    }
    emit(current.copyWith(mutating: true, clearError: true));
    try {
      final response = await semesterRepository.delete(id: id);
      if (!response.success) {
        emit(current.copyWith(mutating: false, mutationError: response.message));
        return false;
      }
      emit(current.copyWith(
        semesters: current.semesters.where((s) => s.id != id).toList(),
        mutating: false,
      ));
      return true;
    } catch (e) {
      emit(current.copyWith(
        mutating: false,
        mutationError: CoreUtils.getErrorMessage(e),
      ));
      return false;
    }
  }

  Future<SemesterStats?> getStats({required String id}) async {
    try {
      final response = await semesterRepository.getStats(id: id);
      if (!response.success) return null;
      return response.data;
    } catch (_) {
      return null;
    }
  }
}
