import 'dart:math';

import 'vision_types.dart';

/// Implementación para WEB/escritorio (sin ML Kit).
/// En web no hay detección on-device: se usa una estimación.
/// La VALIDACIÓN real de rostro/persona corre en el build móvil (vision_mlkit.dart).
Future<OnDeviceVisionResult> analyzeImage(String path, String captureType) async {
  final rnd = Random(path.hashCode ^ DateTime.now().millisecondsSinceEpoch);
  int s(int a, int b) => a + rnd.nextInt(b - a + 1);

  final clothing = s(45, 95);
  final formality = clothing >= 75
      ? 'FORMAL'
      : clothing >= 55
          ? 'SEMI_FORMAL'
          : 'CASUAL';

  return OnDeviceVisionResult(
    face: s(55, 95),
    clothing: clothing,
    posture: s(40, 95),
    context: s(50, 95),
    formality: formality,
    emotion: 'neutral',
  );
}
