import '../../data/models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, error }

class AuthState {
  const AuthState({this.status = AuthStatus.initial, this.user, this.error});

  final AuthStatus status;
  final UserModel? user;
  final String? error;

  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({AuthStatus? status, UserModel? user, String? error}) => AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: error,
      );
}
