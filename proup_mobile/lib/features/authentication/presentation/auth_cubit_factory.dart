import '../../../core/config/environment_config.dart';
import '../../../core/network/api_client.dart';
import '../data/datasources/auth_remote_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/usecases/login_use_case.dart';
import '../domain/usecases/register_use_case.dart';
import 'cubit/auth_cubit.dart';

class AuthCubitFactory {
  const AuthCubitFactory._();

  static AuthCubit create() {
    final config = EnvironmentConfig.fromDartDefine();
    final apiClient = ApiClient(config: config);

    final datasource = AuthRemoteDatasource(
      apiClient: apiClient,
      endpointConfig: AuthEndpointConfig.fromDartDefine(),
    );

    final repository = AuthRepositoryImpl(datasource);

    return AuthCubit(
      loginUseCase: LoginUseCase(repository), 
      registerUseCase: RegisterUseCase(repository),
    );
  }
}