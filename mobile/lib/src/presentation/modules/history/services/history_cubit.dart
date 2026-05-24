import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:study_time_tracker/core/utils/core_utils.dart';
import 'package:study_time_tracker/src/domain/models/session/study_session.dart';
import 'package:study_time_tracker/src/domain/repositories/session_repository_intf.dart';

part 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit({required this.sessionRepository})
      : super(const HistoryInitial());

  final ISessionRepository sessionRepository;

  Future<void> load() async {
    try {
      emit(const HistoryLoading());
      final response = await sessionRepository.getAll();
      final sessions = [...response.data]
        ..sort((a, b) => b.startTime.compareTo(a.startTime));
      emit(HistoryLoaded(sessions: sessions));
    } catch (e) {
      emit(HistoryError(errorMessage: CoreUtils.getErrorMessage(e)));
    }
  }
}
