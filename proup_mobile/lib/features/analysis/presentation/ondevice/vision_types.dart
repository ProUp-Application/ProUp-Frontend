/// Resultado del análisis de visión ON-DEVICE.
class OnDeviceVisionResult {
  const OnDeviceVisionResult({
    required this.face,
    required this.clothing,
    required this.posture,
    required this.context,
    required this.formality,
    required this.emotion,
    this.issues = const [],
    this.metrics = const {},
  });

  final int face;
  final int clothing;
  final int posture;
  final int context;
  final String formality;
  final String emotion;

  /// Problemas detectados que restan profesionalismo (lentes de sol, gorra,
  /// poca luz, rostro girado…). Se muestran al usuario como sugerencias.
  final List<String> issues;

  /// Métricas crudas NO biométricas (ojos abiertos, sonrisa, giro, luminancia…).
  /// Sirven para auditoría/depuración; no reconstruyen el rostro.
  final Map<String, dynamic> metrics;
}

/// Se lanza cuando la imagen no contiene una persona/rostro válido.
class InvalidImageException implements Exception {
  const InvalidImageException(this.message);
  final String message;
}
