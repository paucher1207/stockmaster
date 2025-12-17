// presentation/cubits/auth_state.dart
part of 'auth_cubit.dart';

@immutable
abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  
  const AuthAuthenticated(this.user);
}

class AuthError extends AuthState {
  final String message;
  
  const AuthError(this.message);
}