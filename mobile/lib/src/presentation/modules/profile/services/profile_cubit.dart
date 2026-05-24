import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:study_time_tracker/core/utils/core_utils.dart';
import 'package:study_time_tracker/src/domain/models/user/user_profile.dart';
import 'package:study_time_tracker/src/domain/repositories/authentication_repository_intf.dart';
import 'package:study_time_tracker/src/domain/services/token_storage_service_intf.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required this.authRepository,
    required this.tokenStorage,
  }) : super(const ProfileInitial());

  final IAuthenticationRepository authRepository;
  final ITokenStorageService tokenStorage;

  Future<void> load() async {
    try {
      emit(const ProfileLoading());
      final response = await authRepository.getProfile();
      if (!response.success || response.data == null) {
        emit(ProfileError(
          errorMessage: response.message.isNotEmpty
              ? response.message
              : 'Could not load your profile.',
        ));
        return;
      }
      emit(ProfileLoaded(profile: response.data!));
    } catch (e) {
      emit(ProfileError(errorMessage: CoreUtils.getErrorMessage(e)));
    }
  }

  /// Deletes the account on the server, clears local tokens, then transitions
  /// to [ProfileDeleted]. The router redirects to /login once the token
  /// storage's [isAuthenticated] listenable flips. On failure, returns to the
  /// previous loaded state with [ProfileLoaded.deleteError] populated.
  Future<void> deleteAccount({required String password}) async {
    final current = state;
    if (current is! ProfileLoaded) return;

    emit(current.copyWith(deleting: true, clearError: true));
    try {
      await authRepository.deleteAccount(password: password);
      await tokenStorage.clearAll();
      emit(const ProfileDeleted());
    } catch (e) {
      emit(
        current.copyWith(
          deleting: false,
          deleteError: CoreUtils.getErrorMessage(e),
        ),
      );
    }
  }
}
