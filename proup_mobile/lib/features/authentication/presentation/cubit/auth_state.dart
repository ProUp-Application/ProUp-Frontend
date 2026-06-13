enum AuthStatus {
  initial,
  loading,
  authenticated,
  failure,
}

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
  });

  final AuthStatus status;
  final String? errorMessage;

  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}