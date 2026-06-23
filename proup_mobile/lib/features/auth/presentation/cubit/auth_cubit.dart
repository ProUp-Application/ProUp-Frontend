import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repo) : super(const AuthState());

  final AuthRepository _repo;

  Future<void> login({required String email, required String password}) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final user = await _repo.login(email: email, password: password);
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } catch (e) {
      emit(AuthState(status: AuthStatus.error, error: _message(e)));
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? profession,
  }) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final user = await _repo.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        profession: profession,
      );
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } catch (e) {
      emit(AuthState(status: AuthStatus.error, error: _message(e)));
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    emit(const AuthState());
  }

  String _message(Object e) =>
      e is AppException ? e.message : 'Ocurrió un error inesperado. Inténtalo de nuevo.';
}
