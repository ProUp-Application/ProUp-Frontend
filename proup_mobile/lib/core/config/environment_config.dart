class EnvironmentConfig {
  const EnvironmentConfig ({
    required this.baseUrl,
  });

  final String baseUrl;

  bool get hasBackend =>
  baseUrl.trim().isNotEmpty;

  factory EnvironmentConfig.fromDartDefine() {
    return const EnvironmentConfig(baseUrl: String.fromEnvironment('API_BASE_URL'),
    );
  }
}