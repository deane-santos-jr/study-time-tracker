part of 'profile_cubit.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => const [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  const ProfileLoaded({
    required this.profile,
    this.deleting = false,
    this.deleteError,
  });

  final UserProfile profile;

  /// True while a delete-account request is in flight. Drives the modal's
  /// spinner + disables the confirm button.
  final bool deleting;

  /// Last delete-account failure message, surfaced inside the modal. Cleared
  /// when the next attempt starts.
  final String? deleteError;

  ProfileLoaded copyWith({
    UserProfile? profile,
    bool? deleting,
    String? deleteError,
    bool clearError = false,
  }) {
    return ProfileLoaded(
      profile: profile ?? this.profile,
      deleting: deleting ?? this.deleting,
      deleteError: clearError ? null : (deleteError ?? this.deleteError),
    );
  }

  @override
  List<Object?> get props => [profile, deleting, deleteError];
}

class ProfileError extends ProfileState {
  const ProfileError({required this.errorMessage});

  final String errorMessage;

  @override
  List<Object?> get props => [errorMessage];
}

/// Terminal state — the account is gone. The router redirects to /login as
/// soon as token storage's [ITokenStorageService.isAuthenticated] flips.
class ProfileDeleted extends ProfileState {
  const ProfileDeleted();
}
