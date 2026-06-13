import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../dtos/login_request_dto.dart';
import '../dtos/register_request_dto.dart';
import '../mappers/auth_mapper.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDatasource);

  final AuthRemoteDatasource _remoteDatasource;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final dto = await _remoteDatasource.login(
        LoginRequestDto(
          email: email,
          password: password,
        ),
      );

      return dto.toDomain();
    } on AppException {
      rethrow;
    } catch (_) {
      throw const UnknownException('No se pudo iniciar sesión.');
    }
  }

  @override
  Future<AuthSession> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final dto = await _remoteDatasource.register(
        RegisterRequestDto(
          fullName: fullName,
          email: email,
          password: password,
        ),
      );

      return dto.toDomain();
    } on AppException {
      rethrow;
    } catch (_) {
      throw const UnknownException('No se pudo crear la cuenta.');
    }
  }
}