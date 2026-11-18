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
    this.faceLuminance,
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

  /// Luminancia media de la zona del ROSTRO (0..1). Es la señal de iluminación:
  /// un fondo blanco de estudio sube la luminancia de la foto sin que el rostro
  /// esté sobreexpuesto. null si no se pudo medir (se usa la de la foto).
  final double? faceLuminance;

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
/// Prendas que por sí solas indican vestimenta formal.
const formalHints = ['suit', 'tie', 'blazer', 'tuxedo', 'formal wear', 'dress shirt'];

/// Una casaca puede ser formal o casual: solo suma formalidad junto a otras señales.
const jacketHints = ['jacket'];
const casualHints = ['t-shirt', 'shorts', 'jeans', 'denim', 'tank', 'hoodie', 'sweatshirt', 'swimwear'];

/// Etiquetas que ML Kit confunde con frecuencia ante un saco (p. ej. "tie" o
/// "tuxedo" en un terno sin corbata). Cuentan para la formalidad, pero solo se
/// MUESTRAN al usuario con confianza alta, para no afirmar prendas que no lleva.
const _showThreshold = {'tie': 0.85, 'tuxedo': 0.9};
const _defaultShowThreshold = 0.75;

/// Nombre en español de las prendas que reconoce ML Kit (para explicar el resultado).
const garmentNames = {
  'suit': 'saco o terno',
  'tie': 'corbata',
  'blazer': 'blazer',
  'tuxedo': 'saco o terno',
  'formal wear': 'ropa formal',
  'dress shirt': 'camisa de vestir',
  'jacket': 'casaca o chaqueta',
  't-shirt': 'polo',
  'shorts': 'short',
  'jeans': 'jean o pantalón casual',
  'denim': 'jean o pantalón casual',
  'tank': 'bividí',
  'hoodie': 'polera con capucha',
  'sweatshirt': 'polera',
  'swimwear': 'ropa de baño',
};

/// Mano en primer plano: en una foto profesional las manos no deberían tapar ni
/// acompañar el rostro con gestos (saludo, "V", etc.).
const handHints = ['hand', 'finger', 'gesture', 'thumb'];

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

/// Prendas que se muestran como evidencia: sin duplicados en español (se conserva
/// la confianza mayor) y solo las que ML Kit reconoce con seguridad. Si ninguna
/// supera el umbral, se muestra la más probable para no dejar el puntaje sin motivo.
String _garmentList(Map<String, double> g) {
  final byName = <String, double>{};
  for (final e in g.entries) {
    if (e.value < (_showThreshold[e.key] ?? _defaultShowThreshold)) continue;
    final name = garmentNames[e.key] ?? e.key;
    byName[name] = max(byName[name] ?? 0, e.value);
  }
  if (byName.isEmpty && g.isNotEmpty) {
    final top = g.entries.reduce((a, b) => a.value >= b.value ? a : b);
    byName[garmentNames[top.key] ?? top.key] = top.value;
  }
  final sorted = byName.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return sorted.map((e) => '${e.key} (${_pct(e.value)})').join(', ');
}

double _maxConf(Map<String, double> g) => g.values.fold<double>(0, max);

/// Hasta qué proporción del área puede ocupar el rostro para considerar la foto
/// de medio cuerpo cuando se ven los hombros pero no la cadera (pecho hacia arriba).
const maxFaceRatioForHalfBodyWithoutHips = 0.06;

/// Encuadre según las partes del cuerpo visibles. Un rostro muy grande indica
/// primer plano aunque Pose Detection crea ver hombros o cadera.
FrameType detectFrame(BodyVisibility body, double faceRatio) {
  if (faceRatio >= 0.18) return FrameType.primerPlano;
  if (body.shoulders && body.hips && (body.ankles || body.knees)) {
    return body.ankles ? FrameType.cuerpoCompleto : FrameType.medioCuerpo;
  }
  if (body.shoulders && body.hips) return FrameType.medioCuerpo;
  // Retrato de pecho hacia arriba (p. ej. brazos cruzados que tapan la cadera):
  // el rostro es pequeño y se ve el torso, así que no es un primer plano.
  if (body.shoulders && faceRatio < maxFaceRatioForHalfBodyWithoutHips) return FrameType.medioCuerpo;
  return FrameType.primerPlano;
}

/// Puntaje de iluminación (0..1) con una franja adecuada amplia: no castiga
/// fondos claros de estudio ni luz cálida, solo la oscuridad o la sobreexposición.
double lightQuality(double lum) {
  if (lum < 0.30) return (lum / 0.30).clamp(0.0, 1.0) * 0.8;
  if (lum <= 0.80) return 1.0;
  return (1 - (lum - 0.80) / 0.20).clamp(0.0, 1.0);
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
  // La iluminación se juzga en el rostro; la de toda la foto solo si no se midió
  final lightLum = s.faceLuminance ?? s.luminance;
  final lowLight = lightLum < 0.22;
  // Una mano muy visible en un primer plano suele ser un gesto (saludo, "V")
  final handConf = labelConfidence(s.labels, handHints);
  final handGesture = frame == FrameType.primerPlano && handConf >= 0.85;

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
    if (roll > 12) 'Cabeza inclinada ${roll.round()}° (conviene mantenerla recta)',
  ];
  if (sunglassesDetected) {
    face -= 50; // con los ojos tapados la foto no es profesional
    faceEvidence.add('Ojos no visibles (lentes de sol o lentes oscuros)');
    issues.add('Lentes de sol o ojos no visibles: quítatelos para una foto profesional.');
  } else {
    faceEvidence.add('Ojos visibles');
  }
  if (handGesture) {
    face -= 12;
    faceEvidence.add('Se ve una mano o un gesto junto al rostro (${_pct(handConf)})');
    issues.add('Se ve tu mano haciendo un gesto: para una foto profesional, deja las manos fuera del encuadre.');
  }
  if (lowLight) face -= 10;
  if (yaw > 25) issues.add('Tu rostro está muy girado: mira de frente a la cámara.');
  final faceScore = face.round().clamp(8, 98);
  evaluated.add(CategoryEvidence('face', faceEvidence));

  // ---------- Vestimenta: solo lo que se ve ----------
  final formal = visibleGarments(s.labels, formalHints);
  final jacket = visibleGarments(s.labels, jacketHints);
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
  } else if (formal.isEmpty && jacket.isEmpty && casual.isEmpty && !hasHat) {
    notEvaluated.add(const NotEvaluated(
      'clothing',
      'No identificamos tus prendas con suficiente claridad, así que no asumimos tu vestimenta. Para evaluarla, que la ropa se vea completa y nítida.',
    ));
  } else {
    final clothingEvidence = <String>[];
    final formalConf = _maxConf(formal);
    final casualConf = _maxConf(casual);
    final jacketConf = _maxConf(jacket);
    // Gana la señal más segura: un "jacket" dudoso no vuelve formal a un jean y
    // polo, y una prenda casual dudosa no anula un terno bien reconocido.
    if (formal.isNotEmpty && formalConf >= casualConf) {
      final mixed = casual.isNotEmpty && casualConf >= 0.75;
      clothing = mixed ? 68 : 85;
      formality = mixed ? 'SEMI_FORMAL' : 'FORMAL';
      final garments = _garmentList({...formal, ...jacket});
      clothingEvidence.add('Prendas formales: $garments');
      formalityEvidence.add('Formal porque se ve: $garments.');
      if (mixed) {
        clothingEvidence.add('También se ven prendas casuales: ${_garmentList(casual)}');
        formalityEvidence
          ..clear()
          ..add('Semi formal porque combina $garments con ${_garmentList(casual)}.');
      }
    } else if (casual.isNotEmpty) {
      // Casaca reconocida con seguridad sobre ropa casual → semi formal
      final withJacket = jacketConf >= 0.8 || (formal.isNotEmpty && formalConf >= 0.75);
      clothing = withJacket ? 64 : 52;
      formality = withJacket ? 'SEMI_FORMAL' : 'CASUAL';
      clothingEvidence.add('Prendas casuales: ${_garmentList(casual)}');
      formalityEvidence.add(withJacket
          ? 'Semi formal porque combina ${_garmentList({...jacket, ...formal})} con ${_garmentList(casual)}.'
          : 'Casual porque se ve: ${_garmentList(casual)}.');
    } else if (jacket.isNotEmpty) {
      clothing = 70;
      formality = 'SEMI_FORMAL';
      clothingEvidence.add('Se ve una casaca o chaqueta (${_pct(jacketConf)}), sin otras prendas formales identificadas');
      formalityEvidence.add('Semi formal: se ve una casaca o chaqueta, pero ninguna prenda claramente formal (saco, corbata, camisa de vestir).');
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
      final scope = frame == FrameType.primerPlano || !s.body.hips
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
  if (frame == FrameType.primerPlano || p == null) {
    notEvaluated.add(NotEvaluated(
      'posture',
      frame != FrameType.primerPlano
          ? 'No logramos ubicar bien tus hombros, así que no evaluamos la postura.'
          : s.body.shoulders
              ? 'Es un primer plano: se ve muy poco del torso para juzgar la postura, así que no la evaluamos. Para evaluarla, toma una foto de medio cuerpo o cuerpo entero.'
              : 'Es un primer plano: no se ven tus hombros, así que no evaluamos la postura. Para evaluarla, toma una foto de medio cuerpo o cuerpo entero.',
    ));
  } else {
    final level = p.shoulderLevelness.clamp(0.0, 1.0);
    final vertical = p.torsoVerticality?.clamp(0.0, 1.0);
    // Sin cadera a la vista solo se juzga la alineación de los hombros
    posture = vertical == null
        ? (40 + level * 52).round().clamp(40, 92)
        : (35 + level * 35 + vertical * 28).round().clamp(35, 98);
    evaluated.add(CategoryEvidence('posture', [
      level >= 0.85 ? 'Hombros nivelados (${_pct(level)})' : 'Hombros a distinta altura (${_pct(level)})',
      if (vertical != null) vertical >= 0.8 ? 'Torso recto (${_pct(vertical)})' : 'Torso inclinado (${_pct(vertical)})',
      if (vertical == null)
        'No se ve la cadera: solo evaluamos la alineación de tus hombros'
      else if (frame == FrameType.medioCuerpo)
        'Se evaluó la postura de la parte superior del cuerpo',
    ]));
  }

  // ---------- Entorno: luz ideal ~0.55 y encuadre según el tipo de foto ----------
  final light = lightQuality(lightLum);
  final ideal = idealFaceRatio(frame);
  final framing = (1 - ((s.faceRatio - ideal).abs() / max(ideal * 2, 0.04))).clamp(0.0, 1.0);
  double context = 30 + light * 60 + framing * 10;
  // Contraluz: el fondo mucho más iluminado que el rostro
  final backlit = s.faceLuminance != null && s.luminance - s.faceLuminance! > 0.35;
  final where = s.faceLuminance != null ? ' en tu rostro' : '';
  final contextEvidence = <String>[
    lowLight
        ? 'Iluminación baja$where'
        : light >= 0.95
            ? 'Iluminación adecuada$where'
            : lightLum > 0.80
                ? 'Iluminación excesiva$where (zonas muy claras)'
                : 'Iluminación algo baja$where',
    framing >= 0.6 ? 'Buen encuadre para un(a) ${frame.label.toLowerCase()}' : 'Encuadre mejorable para un(a) ${frame.label.toLowerCase()}',
  ];
  if (backlit) {
    context -= 12;
    contextEvidence.add('Contraluz: el fondo está mucho más iluminado que tu rostro');
    issues.add('Hay contraluz: ponte de frente a la fuente de luz, no de espaldas a ella.');
  }
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
      'faceLuminance': s.faceLuminance == null ? null : double.parse(s.faceLuminance!.toStringAsFixed(2)),
      'handGesture': handGesture,
      'faceRatio': double.parse(s.faceRatio.toStringAsFixed(3)),
      'sunglasses': sunglassesDetected,
      'hat': hasHat,
      'frameType': frame.code,
      // Etiquetas de ML Kit (solo texto y confianza, nunca la imagen): permiten
      // auditar por qué se marcó una prenda o un fondo.
      'labels': {
        for (final e in (s.labels.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(15))
          e.key: double.parse(e.value.toStringAsFixed(2)),
      },
      'body': {
        'shoulders': s.body.shoulders,
        'hips': s.body.hips,
        'knees': s.body.knees,
        'ankles': s.body.ankles,
      },
    },
  );
}
