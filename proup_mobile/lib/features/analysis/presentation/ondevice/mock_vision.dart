import 'dart:math';

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

/// PLACEHOLDER del pipeline real de visión por computador on-device.
///
/// En la versión final, este componente ejecutará MediaPipe (468 landmarks +
/// pose), MobileNetV3 (formalidad de vestimenta) y OpenCV (color/luz/fondo)
/// sobre la imagen, SIN enviarla a ningún servidor. Por ahora genera puntajes
/// plausibles para validar el flujo de extremo a extremo.
class MockOnDeviceVision {
  static OnDeviceVisionResult analyze(String imagePath, String captureType) {
    final rnd = Random(imagePath.hashCode ^ DateTime.now().millisecondsSinceEpoch);
    int s(int min, int max) => min + rnd.nextInt(max - min + 1);

    final clothing = s(45, 95);
    final formality = clothing >= 75
        ? 'FORMAL'
        : clothing >= 55
            ? 'SEMI_FORMAL'
            : 'CASUAL';
    const emotions = ['neutral', 'confiado', 'sonriente', 'serio'];

    return OnDeviceVisionResult(
      face: s(55, 95),
      clothing: clothing,
      posture: s(40, 95),
      context: s(50, 95),
      formality: formality,
      emotion: emotions[rnd.nextInt(emotions.length)],
    );
  }
}
