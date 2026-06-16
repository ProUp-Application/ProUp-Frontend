import 'package:dio/dio.dart';

import '../config/environment_config.dart';
import '../errors/app_exception.dart';
import '../storage/token_storage.dart';

/// Cliente HTTP de la app. Inyecta el token JWT en cada petición y
/// traduce los errores de red/servidor a [AppException].
class ApiClient {
  ApiClient({
    required EnvironmentConfig config,
    required TokenStorage tokenStorage,
    Dio? dio,
  })  : _config = config,
        _tokenStorage = tokenStorage,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: config.baseUrl,
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 20),
                contentType: Headers.jsonContentType,
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _tokenStorage.accessToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final EnvironmentConfig _config;
  final TokenStorage _tokenStorage;
  final Dio _dio;

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) =>
      _run(() => _dio.get<T>(path, queryParameters: queryParameters));

  Future<Response<T>> post<T>(String path, {Object? data}) =>
      _run(() => _dio.post<T>(path, data: data));

  Future<Response<T>> put<T>(String path, {Object? data}) =>
      _run(() => _dio.put<T>(path, data: data));

  Future<Response<T>> patch<T>(String path, {Object? data}) =>
      _run(() => _dio.patch<T>(path, data: data));

  Future<Response<T>> delete<T>(String path, {Object? data}) =>
      _run(() => _dio.delete<T>(path, data: data));

  Future<Response<T>> _run<T>(Future<Response<T>> Function() request) async {
    _ensureBackendConfigured();
    try {
      return await request();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  AppException _mapDioError(DioException e) {
    final response = e.response;
    if (response != null) {
      final data = response.data;
      String message = 'Ocurrió un error';
      if (data is Map && data['error'] is Map && data['error']['message'] != null) {
        message = data['error']['message'].toString();
      }
      return ServerException(message);
    }
    return const NetworkException('Sin conexión con el servidor');
  }

  void _ensureBackendConfigured() {
    if (!_config.hasBackend) {
      throw const BackendNotConfiguredException();
    }
  }
}
