import 'package:dio/dio.dart';

import '../auth/auth_notifier.dart';
import '../config/environment_config.dart';
import '../errors/app_exception.dart';
import '../storage/token_storage.dart';

/// Cliente HTTP de la app.
/// - Inyecta el token JWT en cada petición.
/// - Si el access token expiró (401), lo RENUEVA automáticamente con el
///   refresh token y reintenta la petición una vez. Si la renovación falla,
///   cierra la sesión (el router redirige a login).
/// - Traduce errores de red/servidor a [AppException].
class ApiClient {
  ApiClient({
    required EnvironmentConfig config,
    required TokenStorage tokenStorage,
    AuthNotifier? authNotifier,
    Dio? dio,
  })  : _config = config,
        _tokenStorage = tokenStorage,
        _authNotifier = authNotifier,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: config.baseUrl,
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 45),
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
        onError: (e, handler) async {
          final status = e.response?.statusCode;
          final path = e.requestOptions.path;
          final canRefresh = status == 401 &&
              !path.contains('/auth/refresh') &&
              !path.contains('/auth/login') &&
              !path.contains('/auth/register') &&
              e.requestOptions.extra['retried'] != true &&
              (_tokenStorage.refreshToken ?? '').isNotEmpty;

          if (canRefresh) {
            final refreshed = await _tryRefresh();
            if (refreshed) {
              try {
                final req = e.requestOptions;
                req.extra['retried'] = true;
                req.headers['Authorization'] = 'Bearer ${_tokenStorage.accessToken}';
                final res = await _dio.fetch<dynamic>(req);
                return handler.resolve(res);
              } catch (_) {/* cae al manejo normal */}
            } else {
              // Refresh inválido/expirado: sesión terminada de verdad
              await _tokenStorage.clear();
              _authNotifier?.notifyAuthChanged();
            }
          }
          handler.next(e);
        },
      ),
    );
  }

  final EnvironmentConfig _config;
  final TokenStorage _tokenStorage;
  final AuthNotifier? _authNotifier;
  final Dio _dio;

  Future<bool> _tryRefresh() async {
    try {
      final bare = Dio(BaseOptions(
        baseUrl: _config.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ));
      final res = await bare.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': _tokenStorage.refreshToken},
      );
      final token = res.data?['accessToken'] as String?;
      if (token == null || token.isEmpty) return false;
      await _tokenStorage.saveTokens(access: token);
      return true;
    } catch (_) {
      return false;
    }
  }

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

  /// Sube un archivo (multipart/form-data), p. ej. un CV en PDF/Word.
  Future<Response<T>> postFile<T>(
    String path, {
    required List<int> bytes,
    required String filename,
    String field = 'file',
  }) {
    final form = FormData.fromMap({
      field: MultipartFile.fromBytes(bytes, filename: filename),
    });
    return _run(() => _dio.post<T>(path, data: form));
  }

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
