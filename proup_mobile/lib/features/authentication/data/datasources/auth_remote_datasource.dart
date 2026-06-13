import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../dtos/auth_session_dto.dart';
import '../dtos/login_request_dto.dart';
import '../dtos/register_request_dto.dart';

class AuthRemoteDatasource {
  const AuthRemoteDatasource({
    required ApiClient apiClient,
    required AuthEndpointConfig endpointConfig,
  })  : _apiClient = apiClient,
        _endpointConfig = endpointConfig;

  final ApiClient _apiClient;
  final AuthEndpointConfig _endpointConfig;

  Future<AuthSessionDto> login(LoginRequestDto request) async {
    final path = _endpointConfig.loginPath;
    if (path.isEmpty) {
      throw const BackendNotConfiguredException();
    }

    final response = await _apiClient.post<Map<String, dynamic>>(
      path,
      data: request.toJson(),
    );

    return AuthSessionDto.fromJson(response.data!);
  }

  Future<AuthSessionDto> register(RegisterRequestDto request) async {
    final path = _endpointConfig.registerPath;
    if (path.isEmpty) {
      throw const BackendNotConfiguredException();
    }

    final response = await _apiClient.post<Map<String, dynamic>>(
      path,
      data: request.toJson(),
    );

    return AuthSessionDto.fromJson(response.data!);
  }
}

class AuthEndpointConfig {
  const AuthEndpointConfig({
    required this.loginPath,
    required this.registerPath,
  });

  final String loginPath;
  final String registerPath;

  factory AuthEndpointConfig.fromDartDefine() {
    return const AuthEndpointConfig(
      loginPath: String.fromEnvironment('AUTH_LOGIN_PATH'),
      registerPath: String.fromEnvironment('AUTH_REGISTER_PATH'),
    );
  }
}