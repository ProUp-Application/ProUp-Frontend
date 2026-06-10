import 'package:dio/dio.dart';

import '../config/environment_config.dart';
import '../errors/app_exception.dart';

class ApiClient {
  ApiClient({
    required EnvironmentConfig config,
    Dio? dio,
  })  : _config = config,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: config.baseUrl,
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 20),
                contentType: Headers.jsonContentType,
              ),
            );

  final EnvironmentConfig _config;
  final Dio _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    _ensureBackendConfigured();

    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Options? options,
  }) {
    _ensureBackendConfigured();

    return _dio.post<T>(
      path,
      data: data,
      options: options,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Options? options,
  }) {
    _ensureBackendConfigured();

    return _dio.put<T>(
      path,
      data: data,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Options? options,
  }) {
    _ensureBackendConfigured();

    return _dio.delete<T>(
      path,
      data: data,
      options: options,
    );
  }

  void _ensureBackendConfigured() {
    if (!_config.hasBackend) {
      throw const BackendNotConfiguredException();
    }
  }
}