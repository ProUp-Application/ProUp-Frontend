class EnvironmentConfig {
  const EnvironmentConfig({
    required this.baseUrl,
  });

  final String baseUrl;

  bool get hasBackend => baseUrl.trim().isNotEmpty;

  factory EnvironmentConfig.fromDartDefine() {
    // En el emulador de Android, 10.0.2.2 apunta al localhost de la PC.
    // Para iOS simulator usar http://localhost:3000/api/v1
    // Se puede sobreescribir con: flutter run --dart-define API_BASE_URL=...
    return const EnvironmentConfig(
      baseUrl: String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://10.0.2.2:3000/api/v1',
      ),
    );
  }
}
