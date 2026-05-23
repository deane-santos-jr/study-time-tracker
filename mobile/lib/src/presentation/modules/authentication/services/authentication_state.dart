part of 'authentication_cubit.dart';

abstract class AuthenticationState extends Equatable {
  const AuthenticationState();

  @override
  List<Object> get props => [];
}

class AuthenticationInitial extends AuthenticationState {}

class AuthenticationLoading extends AuthenticationState {}

class AuthenticationSuccess extends AuthenticationState {
  const AuthenticationSuccess();
}

class LogoutSuccess extends AuthenticationState {
  const LogoutSuccess();
}

class AuthenticationFailure extends AuthenticationState {
  const AuthenticationFailure({required this.errorMessage});

  final String errorMessage;

  @override
  List<Object> get props => [errorMessage];
}
