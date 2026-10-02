import 'dart:math';

import 'vision_types.dart';

/// Señales crudas que entrega ML Kit (o un test) para calcular los puntajes.
/// Separar el cálculo de ML Kit permite probarlo con tests unitarios.
class VisionSignals {
  const VisionSignals({
    required this.smilingProbability,
    required this.leftEyeOpenProbability,
    required this.rightEyeOpenProbability,
    required this.yaw,
    required this.roll,
    required this.luminance,
    required this.faceRatio,
    this.labels = const {},
    this.postureReal,
  });

  final double? smilingProbability;
  final double? leftEyeOpenProbability;
  final double? rightEyeOpenProbability;

  /// Giro horizontal / inclinación de la cabeza en grados (valor absoluto).
  final double yaw;
  final double roll;

  /// Luminancia media de la foto (0..1).
  final double luminance;

  /// Fracción del área de la foto que ocupa el rostro (0..1).
  final double faceRatio;

  /// Etiquetas de escena de ML Kit en minúsculas → confianza (0..1).
  final Map<String, double> labels;

  /// Puntaje de postura calculado con Pose Detection (null si no hay cuerpo).
  final int? postureReal;
}

const documentHints = [
  'paper', 'poster', 'menu', 'brochure', 'magazine', 'newspaper', 'passport',
  'banknote', 'money', 'driving', 'licence', 'license', 'document', 'receipt',
  'wallet', 'screenshot', 'television', 'monitor', 'tablet computer',
];
const headwearHints = ['hat', 'cap', 'headgear', 'helmet', 'beanie', 'sombrero', 'gorra', 'bonnet'];
const eyewearHints = ['sunglasses', 'goggles']; // lentes de VISTA normales NO penalizan
const formalHints = ['suit', 'tie', 'blazer', 'tuxedo', 'formal wear', 'dress shirt', 'jacket'];
const casualHints = ['t-shirt', 'shorts', 'jeans', 'tank', 'hoodie', 'sweatshirt', 'swimwear'];

/// Máxima confianza entre las etiquetas que contienen alguna de las pistas.
double labelConfidence(Map<String, double> labels, List<String> hints) => labels.entries
    .where((e) => hints.any((h) => e.key.contains(h)))
    .fold<double>(0, (acc, e) => max(acc, e.value));

/// Calcula los puntajes (0-100) a partir de señales REALES, sin valores aleatorios.
OnDeviceVisionResult scoreVision(VisionSignals s) {
  final issues = <String>[];

  // ---------- Accesorios que restan profesionalismo ----------
  final hasHat = labelConfidence(s.labels, headwearHints) >= 0.5;
  final sunglassesLabel = labelConfidence(s.labels, eyewearHints) >= 0.5;
  final docConfidence = labelConfidence(s.labels, documentHints);

  // ---------- Ojos / lentes de sol ----------
  // Con lentes OSCUROS, ML Kit da una probabilidad de "ojo abierto" muy baja o,
  // si no logra ver los ojos, no la calcula (null) aunque sí clasifique la sonrisa.
  final left = s.leftEyeOpenProbability;
  final right = s.rightEyeOpenProbability;
  final classified = s.smilingProbability != null;
  final double? eyeOpen = (left != null && right != null) ? (left + right) / 2 : null;
  final eyesHidden = (eyeOpen != null && eyeOpen < 0.15) || (classified && eyeOpen == null);
  final sunglassesDetected = sunglassesLabel || eyesHidden;

  // ---------- Señales del rostro ----------
  final smile = (s.smilingProbability ?? 0.5).clamp(0.0, 1.0);
  final yaw = s.yaw.abs().clamp(0.0, 45.0);
  final roll = s.roll.abs().clamp(0.0, 45.0);
  final lowLight = s.luminance < 0.22;

  // ---------- Rostro: base 40 + expresión (0-25) + frontalidad (0-20) + inclinación (0-5) + ojos (0-15)
  double face = 40;
  face += smile * 25;
  face += (1 - yaw / 45) * 20;
  face += (1 - roll / 45) * 5;
  face += (eyeOpen ?? (classified ? 0.0 : 0.7)) * 15;
  if (sunglassesDetected) {
    face -= 50; // con los ojos tapados la foto no es profesional
    issues.add('Lentes de sol o ojos no visibles: quítatelos para una foto profesional.');
  }
  if (lowLight) face -= 10;
  if (yaw > 25) issues.add('Tu rostro está muy girado: mira de frente a la cámara.');

  // ---------- Vestimenta: base determinista + penalización por accesorios ----------
  final hasFormal = formalHints.any((k) => s.labels.keys.any((l) => l.contains(k)));
  final hasCasual = casualHints.any((k) => s.labels.keys.any((l) => l.contains(k)));
  int clothing;
  String formality;
  if (hasFormal) {
    clothing = 82;
    formality = 'FORMAL';
  } else if (hasCasual) {
    clothing = 52;
    formality = 'CASUAL';
  } else {
    clothing = 60; // sin señal clara: neutro, no favorable
    formality = 'SEMI_FORMAL';
  }
  if (hasHat) {
    clothing -= 15;
    issues.add('Se detectó una gorra o sombrero: evítalos en una foto para entrevista.');
  }
  if (sunglassesDetected) clothing -= 12;

  // ---------- Entorno: luz ideal ~0.55 y rostro ~12% del encuadre ----------
  final light = (1 - ((s.luminance - 0.55).abs() / 0.45)).clamp(0.0, 1.0);
  final framing = (1 - ((s.faceRatio - 0.12).abs() / 0.25)).clamp(0.0, 1.0);
  double context = 30 + light * 60 + framing * 10;
  if (docConfidence >= 0.4) context -= 15; // fondo con papeles/pantallas distrae
  if (lowLight) {
    issues.add('Iluminación baja: ubícate frente a una fuente de luz y vuelve a intentarlo.');
  }

  return OnDeviceVisionResult(
    face: face.round().clamp(8, 98),
    clothing: clothing.clamp(15, 95),
    // Sin landmarks de cuerpo (típico en selfie): valor neutro, no aleatorio.
    posture: s.postureReal ?? 55,
    context: context.round().clamp(10, 98),
    formality: formality,
    emotion: smile > 0.5 ? 'sonriente' : 'neutral',
    issues: issues,
    metrics: {
      'eyeOpen': eyeOpen == null ? null : double.parse(eyeOpen.toStringAsFixed(2)),
      'smile': double.parse(smile.toStringAsFixed(2)),
      'yaw': yaw.round(),
      'roll': roll.round(),
      'luminance': double.parse(s.luminance.toStringAsFixed(2)),
      'faceRatio': double.parse(s.faceRatio.toStringAsFixed(3)),
      'sunglasses': sunglassesDetected,
      'hat': hasHat,
    },
  );
}
