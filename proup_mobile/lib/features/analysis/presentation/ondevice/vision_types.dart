/// Resultado del análisis de visión ON-DEVICE.
class OnDeviceVisionResult {
  const OnDeviceVisionResult({
    required this.face,
    required this.clothing,
    required this.posture,
    required this.context,
    required this.formality,
    required this.emotion,
  });

  final int face;
  final int clothing;
  final int posture;
  final int context;
  final String formality;
  final String emotion;
}

/// Se lanza cuando la imagen no contiene una persona/rostro válido.
class InvalidImageException implements Exception {
  const InvalidImageException(this.message);
  final String message;
}
