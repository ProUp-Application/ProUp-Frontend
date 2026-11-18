import 'vision_types.dart';

/// Implementación para WEB/escritorio: no hay ML Kit, así que no se inventan
/// puntajes. El análisis de imagen solo está disponible en la app móvil.
Future<OnDeviceVisionResult> analyzeImage(String path, String captureType) async {
  throw const InvalidImageException(
    'El análisis de imagen funciona en la app de Android, donde la foto se procesa en tu teléfono.',
  );
}
