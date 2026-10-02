import 'package:flutter_test/flutter_test.dart';
import 'package:proup_mobile/features/analysis/presentation/ondevice/vision_scoring.dart';
import 'package:proup_mobile/features/analysis/presentation/ondevice/vision_types.dart';

/// Mismo cálculo que el backend (ProUp-Backend/src/modules/analysis/scoring.ts,
/// pesos "default") para validar la banda final que vería el usuario.
int overall(OnDeviceVisionResult r) =>
    (r.face * 0.3 + r.clothing * 0.3 + r.posture * 0.25 + r.context * 0.15).round();

String band(int score) => score < 50 ? 'Por mejorar' : (score < 75 ? 'Aceptable' : 'Profesional');

/// Selfie "buena" de referencia: frontal, ojos abiertos, buena luz y encuadre.
VisionSignals signals({
  double? smile = 0.7,
  double? leftEye = 0.95,
  double? rightEye = 0.95,
  double yaw = 3,
  double roll = 2,
  double luminance = 0.55,
  double faceRatio = 0.12,
  Map<String, double> labels = const {},
  int? posture,
}) =>
    VisionSignals(
      smilingProbability: smile,
      leftEyeOpenProbability: leftEye,
      rightEyeOpenProbability: rightEye,
      yaw: yaw,
      roll: roll,
      luminance: luminance,
      faceRatio: faceRatio,
      labels: labels,
      postureReal: posture,
    );

void main() {
  group('Caso reportado por el asesor: gorra + lentes de sol', () {
    test('ya NO sale favorable: queda en "Por mejorar" y avisa ambos problemas', () {
      final r = scoreVision(signals(
        leftEye: 0.02,
        rightEye: 0.03,
        labels: {'cap': 0.82, 'sunglasses': 0.88, 'person': 0.9},
      ));

      expect(band(overall(r)), 'Por mejorar', reason: 'overall=${overall(r)} $r');
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
    test('selfie frontal, formal y bien iluminada → "Profesional" sin avisos', () {
      final r = scoreVision(signals(labels: {'suit': 0.8, 'tie': 0.7}, posture: 85));
      expect(r.issues, isEmpty);
      expect(r.formality, 'FORMAL');
      expect(band(overall(r)), 'Profesional', reason: 'overall=${overall(r)}');
    });

    test('lentes de VISTA (no de sol) no penalizan', () {
      final r = scoreVision(signals(labels: {'glasses': 0.9}));
      expect(r.metrics['sunglasses'], isFalse);
      expect(r.issues, isEmpty);
    });
  });

  group('Penalizaciones individuales', () {
    test('solo gorra baja la vestimenta y avisa', () {
      final base = scoreVision(signals());
      final hat = scoreVision(signals(labels: {'hat': 0.75}));
      expect(hat.clothing, base.clothing - 15);
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

  test('puntajes exactos usados en la prueba E2E del backend', () {
    List<int> scores(OnDeviceVisionResult r) => [r.face, r.clothing, r.posture, r.context];
    expect(
      scores(scoreVision(signals(leftEye: 0.02, rightEye: 0.03, labels: {'cap': 0.82, 'sunglasses': 0.88}))),
      [31, 33, 55, 98],
    );
    expect(scores(scoreVision(signals(labels: {'hat': 0.75}))), [95, 45, 55, 98]);
    expect(scores(scoreVision(signals(labels: {'suit': 0.8, 'tie': 0.7}, posture: 85))), [95, 82, 85, 98]);
  });

  test('es determinista: la misma foto da siempre el mismo puntaje (sin aleatorios)', () {
    final a = scoreVision(signals(labels: {'jeans': 0.7}));
    final b = scoreVision(signals(labels: {'jeans': 0.7}));
    expect([a.face, a.clothing, a.posture, a.context], [b.face, b.clothing, b.posture, b.context]);
  });
}
