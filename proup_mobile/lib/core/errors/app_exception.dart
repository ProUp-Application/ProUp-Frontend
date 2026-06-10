sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;
}

class BackendNotConfiguredException extends AppException {
  const BackendNotConfiguredException():super('Backend not configured. Please set the API_BASE_URL environment variable.');
}

class NetworkException extends AppException {
  const NetworkException(super.message);
}

class ServerException extends AppException {
  const ServerException(super.message);
}

class UnknownException extends AppException {
  const UnknownException(super.message);
}