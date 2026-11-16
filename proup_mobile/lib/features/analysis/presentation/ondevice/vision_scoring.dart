import 'dart:math';

import 'vision_types.dart';

/// Partes del cuerpo visibles en la foto, según los puntos de Pose Detection
/// (se considera visible un punto con probabilidad de estar en la imagen ≥ 0.5).
class BodyVisibility {
  const BodyVisibility({
    this.shoulders = false,
    this.hips = false,
    this.knees = false,
    this.ankles = false,
  });

  final bool shoulders;
  final bool hips;
  final bool knees;
  final bool ankles;

  static const none = BodyVisibility();
}

/// Señales de postura calculadas con los puntos del cuerpo (0..1).
class PostureSignals {
  const PostureSignals({required this.shoulderLevelness, this.torsoVerticality});

  /// 1 = hombros a la misma altura.
  final double shoulderLevelness;

  /// 1 = torso vertical (hombros sobre la cadera). null si no se ve la cadera.
  final double? torsoVerticality;
}

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
    this.body = BodyVisibility.none,
    this.posture,
    this.requestedCapture,
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

  /// Qué partes del cuerpo aparecen en la foto.
  final BodyVisibility body;

  /// Señales de postura (null si Pose Detection no encontró el cuerpo).
  final PostureSignals? posture;

  /// Lo que eligió el usuario al capturar (SELFIE / FULL_BODY), para avisarle si
  /// la foto no coincide con lo que quería evaluar.
  final String? requestedCapture;
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

/// Nombre en español de las prendas que reconoce ML Kit (para explicar el resultado).
const garmentNames = {
  'suit': 'saco o terno',
  'tie': 'corbata',
  'blazer': 'blazer',
  'tuxedo': 'esmoquin',
  'formal wear': 'ropa formal',
  'dress shirt': 'camisa de vestir',
  'jacket': 'casaca o chaqueta',
  't-shirt': 'polo',
  'shorts': 'short',
  'jeans': 'jean',
  'tank': 'bividí',
  'hoodie': 'polera con capucha',
  'sweatshirt': 'polera',
  'swimwear': 'ropa de baño',
};

/// Máxima confianza entre las etiquetas que contienen alguna de las pistas.
double labelConfidence(Map<String, double> labels, List<String> hints) => labels.entries
    .where((e) => hints.any((h) => e.key.contains(h)))
    .fold<double>(0, (acc, e) => max(acc, e.value));

/// Prendas visibles identificadas (pista → confianza), con confianza ≥ 0.5.
Map<String, double> visibleGarments(Map<String, double> labels, List<String> hints) {
  final out = <String, double>{};
  for (final h in hints) {
    final conf = labelConfidence(labels, [h]);
    if (conf >= 0.5) out[h] = conf;
  }
  return out;
}

String _pct(double v) => '${(v * 100).round()}%';

String _garmentList(Map<String, double> g) =>
    g.entries.map((e) => '${garmentNames[e.key] ?? e.key} (${_pct(e.value)})').join(', ');

/// Encuadre según las partes del cuerpo visibles. Un rostro muy grande indica
/// primer plano aunque Pose Detection crea ver hombros o cadera.
FrameType detectFrame(BodyVisibility body, double faceRatio) {
  if (faceRatio >= 0.18) return FrameType.primerPlano;
  if (body.shoulders && body.hips && (body.ankles || body.knees)) {
    return body.ankles ? FrameType.cuerpoCompleto : FrameType.medioCuerpo;
  }
  if (body.shoulders && body.hips) return FrameType.medioCuerpo;
  return FrameType.primerPlano;
}

/// Proporción ideal del rostro en la foto según el encuadre (para puntuar el encuadre).
double idealFaceRatio(FrameType f) => switch (f) {
      FrameType.primerPlano => 0.12,
      FrameType.medioCuerpo => 0.05,
      FrameType.cuerpoCompleto => 0.015,
    };

/// Calcula los puntajes (0-100) a partir de señales REALES, sin valores aleatorios,
/// evaluando SOLO lo que se ve en la foto y explicando cada puntaje.
OnDeviceVisionResult scoreVision(VisionSignals s) {
  final issues = <String>[];
  final evaluated = <CategoryEvidence>[];
  final notEvaluated = <NotEvaluated>[];
  final frame = detectFrame(s.body, s.faceRatio);

  // ---------- Accesorios que restan profesionalismo ----------
  final hatConf = labelConfidence(s.labels, headwearHints);
  final hasHat = hatConf >= 0.5;
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

  // ---------- Rostro y expresión (siempre visible: sin rostro no hay análisis) ----------
  final smile = (s.smilingProbability ?? 0.5).clamp(0.0, 1.0);
  final yaw = s.yaw.abs().clamp(0.0, 45.0);
  final roll = s.roll.abs().clamp(0.0, 45.0);
  final lowLight = s.luminance < 0.22;

  double face = 40;
  face += smile * 25;
  face += (1 - yaw / 45) * 20;
  face += (1 - roll / 45) * 5;
  face += (eyeOpen ?? (classified ? 0.0 : 0.7)) * 15;
  final faceEvidence = <String>[
    smile >= 0.6
        ? 'Sonrisa visible (${_pct(smile)})'
        : smile >= 0.3
            ? 'Sonrisa leve (${_pct(smile)})'
            : 'Expresión seria, sin sonrisa (${_pct(smile)})',
    yaw <= 12 ? 'Mirada de frente a la cámara (giro ${yaw.round()}°)' : 'Rostro girado ${yaw.round()}°',
    if (roll > 12) 'Cabeza inclinada ${roll.round()}°',
  ];
  if (sunglassesDetected) {
    face -= 50; // con los ojos tapados la foto no es profesional
    faceEvidence.add('Ojos no visibles (lentes de sol o lentes oscuros)');
    issues.add('Lentes de sol o ojos no visibles: quítatelos para una foto profesional.');
  } else {
    faceEvidence.add('Ojos visibles');
  }
  if (lowLight) face -= 10;
  if (yaw > 25) issues.add('Tu rostro está muy girado: mira de frente a la cámara.');
  final faceScore = face.round().clamp(8, 98);
  evaluated.add(CategoryEvidence('face', faceEvidence));

  // ---------- Vestimenta: solo lo que se ve ----------
  final formal = visibleGarments(s.labels, formalHints);
  final casual = visibleGarments(s.labels, casualHints);
  final upperBodyVisible = s.body.shoulders || frame != FrameType.primerPlano;
  int? clothing;
  String? formality;
  final formalityEvidence = <String>[];
  if (!upperBodyVisible && !hasHat) {
    notEvaluated.add(const NotEvaluated(
      'clothing',
      'La foto solo muestra el rostro: no se ve la ropa, así que no evaluamos la vestimenta.',
    ));
  } else if (formal.isEmpty && casual.isEmpty && !hasHat) {
    notEvaluated.add(const NotEvaluated(
      'clothing',
      'No identificamos prendas con suficiente claridad, así que no asumimos tu vestimenta. Prueba con más luz y la ropa a la vista.',
    ));
  } else {
    final clothingEvidence = <String>[];
    if (formal.isNotEmpty) {
      clothing = 82;
      formality = 'FORMAL';
      clothingEvidence.add('Prendas formales: ${_garmentList(formal)}');
      formalityEvidence.add('Formal porque se ve: ${_garmentList(formal)}.');
    } else if (casual.isNotEmpty) {
      clothing = 52;
      formality = 'CASUAL';
      clothingEvidence.add('Prendas casuales: ${_garmentList(casual)}');
      formalityEvidence.add('Casual porque se ve: ${_garmentList(casual)}.');
    } else {
      clothing = 60; // solo un accesorio a la vista: no hay prendas para valorar formalidad
      clothingEvidence.add('No se identificaron prendas; solo un accesorio en la cabeza');
    }
    if (hasHat) {
      clothing -= 15;
      clothingEvidence.add('Gorra o sombrero (${_pct(hatConf)})');
      issues.add('Se detectó una gorra o sombrero: evítalos en una foto para entrevista.');
    }
    if (sunglassesDetected) clothing -= 12;
    if (frame != FrameType.cuerpoCompleto) {
      final scope = frame == FrameType.primerPlano
          ? 'Solo se ve la parte superior: no evaluamos pantalón ni calzado.'
          : 'Se evaluó de la cintura hacia arriba: no evaluamos pantalón ni calzado.';
      clothingEvidence.add(scope);
      if (formality != null) formalityEvidence.add(scope);
    }
    evaluated.add(CategoryEvidence('clothing', clothingEvidence));
    clothing = clothing.clamp(15, 95);
  }

  // ---------- Postura: requiere ver hombros y cadera ----------
  int? posture;
  final p = s.posture;
  if (frame == FrameType.primerPlano || p == null || p.torsoVerticality == null) {
    notEvaluated.add(NotEvaluated(
      'posture',
      frame == FrameType.primerPlano
          ? 'Es un primer plano: no se ven los hombros y la cadera, así que no evaluamos la postura. Para evaluarla, toma una foto de medio cuerpo o cuerpo entero.'
          : 'No logramos ubicar bien los hombros y la cadera, así que no evaluamos la postura.',
    ));
  } else {
    final level = p.shoulderLevelness.clamp(0.0, 1.0);
    final vertical = p.torsoVerticality!.clamp(0.0, 1.0);
    posture = (35 + level * 35 + vertical * 28).round().clamp(35, 98);
    evaluated.add(CategoryEvidence('posture', [
      level >= 0.85 ? 'Hombros nivelados (${_pct(level)})' : 'Hombros a distinta altura (${_pct(level)})',
      vertical >= 0.8 ? 'Torso recto (${_pct(vertical)})' : 'Torso inclinado (${_pct(vertical)})',
      if (frame == FrameType.medioCuerpo) 'Se evaluó la postura de la parte superior del cuerpo',
    ]));
  }

  // ---------- Entorno: luz ideal ~0.55 y encuadre según el tipo de foto ----------
  final light = (1 - ((s.luminance - 0.55).abs() / 0.45)).clamp(0.0, 1.0);
  final ideal = idealFaceRatio(frame);
  final framing = (1 - ((s.faceRatio - ideal).abs() / max(ideal * 2, 0.04))).clamp(0.0, 1.0);
  double context = 30 + light * 60 + framing * 10;
  final contextEvidence = <String>[
    s.luminance < 0.22
        ? 'Iluminación baja'
        : s.luminance > 0.85
            ? 'Iluminación excesiva o contraluz'
            : 'Iluminación adecuada',
    framing >= 0.6 ? 'Buen encuadre para un(a) ${frame.label.toLowerCase()}' : 'Encuadre mejorable para un(a) ${frame.label.toLowerCase()}',
  ];
  if (docConfidence >= 0.4) {
    context -= 15; // fondo con papeles/pantallas distrae
    contextEvidence.add('Hay papeles o pantallas en el fondo');
  }
  if (lowLight) {
    issues.add('Iluminación baja: ubícate frente a una fuente de luz y vuelve a intentarlo.');
  }
  evaluated.add(CategoryEvidence('context', contextEvidence));

  // Si eligió cuerpo entero pero la foto no lo muestra, se le avisa
  if (s.requestedCapture == 'FULL_BODY' && frame != FrameType.cuerpoCompleto) {
    issues.add(
      'Elegiste foto de cuerpo entero, pero se detectó un ${frame.label.toLowerCase()}: solo evaluaremos lo que se ve.',
    );
  }

  return OnDeviceVisionResult(
    frameType: frame,
    face: faceScore,
    clothing: clothing,
    posture: posture,
    context: context.round().clamp(10, 98),
    formality: formality,
    emotion: smile > 0.5 ? 'sonriente' : 'neutral',
    evaluated: evaluated,
    notEvaluated: notEvaluated,
    formalityEvidence: formalityEvidence,
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
      'frameType': frame.code,
      'body': {
        'shoulders': s.body.shoulders,
        'hips': s.body.hips,
        'knees': s.body.knees,
        'ankles': s.body.ankles,
      },
    },
  );
}
