import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/usecases/login_use_case.dart';
import '../../domain/usecases/register_use_case.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
  }) : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        super(const AuthState());

  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(const AuthState(status: AuthStatus.loading));

    try {
      await _loginUseCase(
        email: email, 
        password: password,
      );
      emit(const AuthState(status: AuthStatus.authenticated));
    } on AppException catch (exception) {
      emit(
        AuthState(
          status: AuthStatus.failure, 
          errorMessage: exception.message,
        ),
      );
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    emit(const AuthState(status: AuthStatus.loading));

    try {
      await _registerUseCase(
        fullName: fullName, 
        email: email, 
        password: password,
      );

      emit(const AuthState(status: AuthStatus.authenticated));
    } on AppException catch (exception) {
      emit(
        AuthState(
          status: AuthStatus.failure,
          errorMessage: exception.message,
        ),
      );
    }
  }
}