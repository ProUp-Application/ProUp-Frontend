import 'package:flutter_test/flutter_test.dart';
import 'package:proup_mobile/features/analysis/presentation/ondevice/vision_scoring.dart';
import 'package:proup_mobile/features/analysis/presentation/ondevice/vision_types.dart';

/// Mismo cálculo que el backend (ProUp-Backend/src/modules/analysis/scoring.ts,
/// pesos "default"): las categorías no evaluadas no cuentan y se renormaliza.
int overall(OnDeviceVisionResult r) {
  final parts = <(int?, double)>[(r.face, 0.3), (r.clothing, 0.3), (r.posture, 0.25), (r.context, 0.15)];
  final used = parts.where((p) => p.$1 != null);
  final w = used.fold<double>(0, (a, p) => a + p.$2);
  return (used.fold<double>(0, (a, p) => a + p.$1! * p.$2) / w).round();
}

String band(int score) => score < 50 ? 'Por mejorar' : (score < 75 ? 'Aceptable' : 'Profesional');

const halfBody = BodyVisibility(shoulders: true, hips: true);
const fullBody = BodyVisibility(shoulders: true, hips: true, knees: true, ankles: true);
const goodPosture = PostureSignals(shoulderLevelness: 0.95, torsoVerticality: 0.9);

/// Foto "buena" de referencia: frontal, ojos abiertos, buena luz y encuadre.
VisionSignals signals({
  double? smile = 0.7,
  double? leftEye = 0.95,
  double? rightEye = 0.95,
  double yaw = 3,
  double roll = 2,
  double luminance = 0.55,
  double faceRatio = 0.12,
  double? faceLuminance,
  Map<String, double> labels = const {},
  BodyVisibility body = BodyVisibility.none,
  PostureSignals? posture,
  String? requested,
}) =>
    VisionSignals(
      smilingProbability: smile,
      leftEyeOpenProbability: leftEye,
      rightEyeOpenProbability: rightEye,
      yaw: yaw,
      roll: roll,
      luminance: luminance,
      faceRatio: faceRatio,
      faceLuminance: faceLuminance,
      labels: labels,
      body: body,
      posture: posture,
      requestedCapture: requested,
    );

void main() {
  group('IMG-01 · Tipo de foto según las partes del cuerpo visibles', () {
    test('sin cuerpo visible es un primer plano', () {
      expect(detectFrame(BodyVisibility.none, 0.12), FrameType.primerPlano);
    });
    test('hombros y cadera sin piernas es medio cuerpo', () {
      expect(detectFrame(halfBody, 0.05), FrameType.medioCuerpo);
    });
    test('con tobillos visibles es cuerpo completo', () {
      expect(detectFrame(fullBody, 0.015), FrameType.cuerpoCompleto);
    });
    test('un rostro muy grande es primer plano aunque la pose crea ver la cadera', () {
      expect(detectFrame(fullBody, 0.25), FrameType.primerPlano);
    });
  });

  group('IMG-02/03 · Solo se evalúa lo que se ve', () {
    test('en un selfie de rostro no se califican ropa ni postura (criterio del asesor)', () {
      final r = scoreVision(signals());
      expect(r.frameType, FrameType.primerPlano);
      expect(r.clothing, isNull);
      expect(r.posture, isNull);
      expect(r.formality, isNull);
      expect(r.notEvaluated.map((n) => n.category), containsAll(['clothing', 'posture']));
      expect(r.notEvaluated.firstWhere((n) => n.category == 'posture').reason, contains('primer plano'));
    });

    test('en un primer plano con hombros y prenda visible se evalúa solo la parte superior', () {
      final r = scoreVision(signals(labels: {'suit': 0.8}, body: const BodyVisibility(shoulders: true)));
      expect(r.clothing, 85);
      expect(r.posture, isNull);
      expect(r.formalityEvidence.join(' '), contains('no evaluamos pantalón ni calzado'));
    });

    test('sin prendas identificadas no se asume la vestimenta (antes era un 60 neutro)', () {
      final r = scoreVision(signals(body: halfBody, posture: goodPosture, faceRatio: 0.05));
      expect(r.clothing, isNull);
      expect(r.notEvaluated.firstWhere((n) => n.category == 'clothing').reason, contains('no asumimos'));
    });

    test('medio cuerpo con hombros y cadera evalúa la postura del torso', () {
      final r = scoreVision(signals(body: halfBody, posture: goodPosture, faceRatio: 0.05, labels: {'jeans': 0.7}));
      expect(r.frameType, FrameType.medioCuerpo);
      expect(r.posture, isNotNull);
      expect(r.evaluated.firstWhere((e) => e.category == 'posture').evidence, contains('Hombros nivelados (95%)'));
    });

    test('cuerpo completo evalúa las 4 categorías', () {
      final r = scoreVision(signals(body: fullBody, posture: goodPosture, faceRatio: 0.015, labels: {'suit': 0.8, 'tie': 0.7}));
      expect(r.frameType, FrameType.cuerpoCompleto);
      expect(r.notEvaluated, isEmpty);
      expect(r.evaluated.length, 4);
    });

    test('si eligió cuerpo entero pero la foto es un primer plano, se le avisa', () {
      final r = scoreVision(signals(requested: 'FULL_BODY'));
      expect(r.issues.any((i) => i.contains('solo evaluaremos lo que se ve')), isTrue);
    });
  });

  group('IMG-04/07 · Explicación del resultado', () {
    test('la formalidad cita las prendas visibles que la sustentan', () {
      final r = scoreVision(signals(labels: {'suit': 0.8, 'tie': 0.7}, body: halfBody, posture: goodPosture, faceRatio: 0.05));
      expect(r.formality, 'FORMAL');
      expect(r.formalityEvidence.first, contains('saco o terno (80%)'));
      // "tie" al 70 % es un falso positivo frecuente con un saco: cuenta, pero no se afirma
      expect(r.formalityEvidence.first, isNot(contains('corbata')));
    });

    test('una corbata reconocida con seguridad sí se muestra', () {
      final r = scoreVision(signals(labels: {'suit': 0.8, 'tie': 0.9}, body: halfBody, posture: goodPosture, faceRatio: 0.05));
      expect(r.formalityEvidence.first, contains('corbata (90%)'));
    });

    test('cada categoría evaluada tiene evidencia y el JSON para el backend la incluye', () {
      final r = scoreVision(signals());
      expect(r.evaluated.every((e) => e.evidence.isNotEmpty), isTrue);
      final json = r.assessmentJson();
      expect((json['evaluated'] as List).length, 2);
      expect((json['notEvaluated'] as List).length, 2);
    });
  });

  group('Caso reportado por el asesor: gorra + lentes de sol', () {
    test('ya NO sale favorable: queda en "Por mejorar" y avisa ambos problemas', () {
      final r = scoreVision(signals(
        leftEye: 0.02,
        rightEye: 0.03,
        labels: {'cap': 0.82, 'sunglasses': 0.88, 'person': 0.9},
      ));
      expect(band(overall(r)), 'Por mejorar', reason: 'overall=${overall(r)}');
      expect(r.face, lessThan(50));
      expect(r.metrics['sunglasses'], isTrue);
      expect(r.metrics['hat'], isTrue);
      expect(r.issues.any((i) => i.contains('Lentes de sol')), isTrue);
      expect(r.issues.any((i) => i.contains('gorra')), isTrue);
    });

    test('lentes oscuros que ML Kit no etiqueta y ojos sin calcular (null) también se detectan', () {
      final r = scoreVision(signals(leftEye: null, rightEye: null));
      expect(r.metrics['sunglasses'], isTrue);
      expect(r.face, lessThan(50));
    });

    test('lentes oscuros sin etiqueta pero con ojos "cerrados" (prob. baja) se detectan', () {
      final r = scoreVision(signals(leftEye: 0.05, rightEye: 0.08));
      expect(r.metrics['sunglasses'], isTrue);
    });
  });

  group('Fotos correctas siguen puntuando bien', () {
    test('foto de medio cuerpo formal, frontal y bien iluminada → "Profesional" sin avisos', () {
      final r = scoreVision(signals(labels: {'suit': 0.8, 'tie': 0.7}, body: halfBody, posture: goodPosture, faceRatio: 0.05));
      expect(r.issues, isEmpty);
      expect(band(overall(r)), 'Profesional', reason: 'overall=${overall(r)}');
    });

    test('lentes de VISTA (no de sol) no penalizan', () {
      final r = scoreVision(signals(labels: {'glasses': 0.9}));
      expect(r.metrics['sunglasses'], isFalse);
      expect(r.issues, isEmpty);
    });

    test('en cuerpo completo un rostro pequeño no castiga el encuadre', () {
      final full = scoreVision(signals(body: fullBody, posture: goodPosture, faceRatio: 0.015, labels: {'suit': 0.8}));
      expect(full.context, greaterThanOrEqualTo(90));
    });
  });

  group('Penalizaciones individuales', () {
    test('la gorra baja la vestimenta y avisa', () {
      final base = scoreVision(signals(labels: {'jacket': 0.7}, body: halfBody, posture: goodPosture, faceRatio: 0.05));
      final hat = scoreVision(signals(labels: {'jacket': 0.7, 'hat': 0.75}, body: halfBody, posture: goodPosture, faceRatio: 0.05));
      expect(hat.clothing, base.clothing! - 15);
      expect(hat.issues.single, contains('gorra'));
    });

    test('poca luz baja el entorno y avisa', () {
      final ok = scoreVision(signals());
      final dark = scoreVision(signals(luminance: 0.1));
      expect(dark.context, lessThan(ok.context));
      expect(dark.issues.any((i) => i.contains('Iluminación baja')), isTrue);
    });

    test('rostro muy girado avisa', () {
      final r = scoreVision(signals(yaw: 35));
      expect(r.issues.any((i) => i.contains('girado')), isTrue);
    });
  });

  test('es determinista: la misma foto da siempre el mismo puntaje (sin aleatorios)', () {
    final a = scoreVision(signals(labels: {'jeans': 0.7}, body: halfBody, posture: goodPosture));
    final b = scoreVision(signals(labels: {'jeans': 0.7}, body: halfBody, posture: goodPosture));
    expect([a.face, a.clothing, a.posture, a.context], [b.face, b.clothing, b.posture, b.context]);
  });

  // Señales REALES medidas por ML Kit en el emulador con las 3 fotos de prueba
  // (traje, selfie con gesto y cuerpo entero con polo y pantalón casual).
  group('Regresión con fotos reales', () {
    test('foto 1 · traje, pecho hacia arriba, brazos cruzados → medio cuerpo formal, postura por hombros', () {
      final r = scoreVision(signals(
        smile: 0.97, leftEye: 0.99, rightEye: 0.99, yaw: 0, roll: 1,
        luminance: 0.72, faceLuminance: 0.6, faceRatio: 0.034,
        body: const BodyVisibility(shoulders: true),
        posture: const PostureSignals(shoulderLevelness: 0.97),
        labels: {'tie': 0.76, 'blazer': 0.76, 'jacket': 0.87, 'tuxedo': 0.54, 'outerwear': 0.88},
      ));
      expect(r.frameType, FrameType.medioCuerpo);
      expect(r.formality, 'FORMAL');
      final ev = r.formalityEvidence.join(' ');
      expect(ev, isNot(contains('corbata')));
      expect(ev, isNot(contains('esmoquin')));
      expect(r.posture, isNotNull);
      expect(r.evaluated.firstWhere((e) => e.category == 'posture').evidence.join(' '), contains('alineación de tus hombros'));
      expect(r.context, greaterThanOrEqualTo(90), reason: 'fondo gris claro de estudio no es mala luz');
    });

    test('foto 2 · selfie con polo y gesto "V" → primer plano, avisa el gesto y no dice "no se ven los hombros"', () {
      final r = scoreVision(signals(
        smile: 0.99, leftEye: 0.43, rightEye: 0.43, yaw: 8, roll: 14,
        luminance: 0.48, faceLuminance: 0.55, faceRatio: 0.093,
        body: const BodyVisibility(shoulders: true),
        posture: const PostureSignals(shoulderLevelness: 0.9),
        labels: {'fun': 0.63, 'dude': 0.66, 'hand': 0.96, 'nail': 0.71, 'smile': 0.78},
      ));
      expect(r.frameType, FrameType.primerPlano);
      expect(r.posture, isNull);
      expect(r.notEvaluated.firstWhere((n) => n.category == 'posture').reason, isNot(contains('no se ven tus hombros')));
      expect(r.issues.any((i) => i.contains('gesto')), isTrue);
      expect(r.metrics['handGesture'], isTrue);
    });

    test('foto 3 · cuerpo entero con polo y pantalón casual → casual (un "jacket" dudoso no la vuelve formal)', () {
      final r = scoreVision(signals(
        smile: 0.99, leftEye: 0.99, rightEye: 0.99, yaw: 7, roll: 3,
        luminance: 0.85, faceLuminance: 0.62, faceRatio: 0.009,
        body: fullBody, posture: const PostureSignals(shoulderLevelness: 0.99, torsoVerticality: 0.96),
        labels: {'cool': 0.88, 'shoe': 0.66, 'denim': 0.86, 'jeans': 0.92, 'jacket': 0.63, 'muscle': 0.83, 'pocket': 0.74, 'shorts': 0.7, 'standing': 0.97},
      ));
      expect(r.frameType, FrameType.cuerpoCompleto);
      expect(r.formality, 'CASUAL');
      expect(r.clothing, lessThan(60));
      expect(r.formalityEvidence.join(' '), isNot(contains('short')), reason: 'short al 70 % no se afirma');
      expect(r.context, greaterThanOrEqualTo(90), reason: 'fondo blanco con rostro bien iluminado');
    });
  });

  group('Iluminación medida en el rostro', () {
    test('contraluz: fondo muy claro y rostro oscuro baja el entorno y avisa', () {
      final ok = scoreVision(signals(luminance: 0.6, faceLuminance: 0.55));
      final back = scoreVision(signals(luminance: 0.85, faceLuminance: 0.3));
      expect(back.context, lessThan(ok.context));
      expect(back.issues.any((i) => i.contains('contraluz')), isTrue);
    });

    test('la evidencia de luz coincide con el puntaje (nada de "adecuada" con un entorno bajo)', () {
      final r = scoreVision(signals(luminance: 0.95, faceLuminance: 0.95));
      expect(r.evaluated.firstWhere((e) => e.category == 'context').evidence.first, contains('excesiva'));
    });
  });
}
