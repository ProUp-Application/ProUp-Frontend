import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proup_mobile/core/errors/app_exception.dart';
import 'package:proup_mobile/core/widgets/connection_banner.dart';
import 'package:proup_mobile/features/analysis/data/models/analysis_models.dart';
import 'package:proup_mobile/features/analysis/presentation/ondevice/vision_types.dart';
import 'package:proup_mobile/features/analysis/presentation/screens/results_screen.dart';

// Respuesta a los hallazgos del ciclo 1 de QA (H01 y H04).
void main() {
  group('H01 · tiempo del análisis en el teléfono (RNF-01)', () {
    test('withAnalysisMs agrega el tiempo a las métricas sin perder las demás', () {
      const v = OnDeviceVisionResult(
        frameType: FrameType.primerPlano,
        face: 80,
        clothing: null,
        posture: null,
        context: 90,
        formality: null,
        emotion: 'NEUTRAL',
        metrics: {'eyeOpen': 0.9},
      );
      final t = v.withAnalysisMs(1432);
      expect(t.analysisMs, 1432);
      expect(t.metrics['eyeOpen'], 0.9);
      expect(t.face, 80);
    });

    test('el resultado lee analysisMs de rawMetrics', () {
      final r = AnalysisResultModel.fromJson({
        'id': 'x',
        'faceScore': 80,
        'contextScore': 90,
        'overallScore': 85,
        'rawMetrics': {'analysisMs': 1432},
      });
      expect(r.analysisMs, 1432);
      expect(AnalysisResultModel.fromJson({'id': 'y'}).analysisMs, isNull);
    });

    test('el texto usa coma decimal', () {
      expect(processingTimeLabel(1432), 'Procesado en tu teléfono en 1,4 s');
    });
  });

  group('H04 · aviso fijo de conexión', () {
    testWidgets('se queda visible y "Reintentar" llama a la acción', (tester) async {
      var retries = 0;
      ConnectionIssue? issue = ConnectionIssue.from(
        const NetworkException('Sin conexión con el servidor'),
        'No se pudo iniciar la simulación. Revisa tu conexión.',
        retry: () => retries++,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder:
                (context, setState) => Scaffold(
                  body: WithConnectionBanner(
                    issue: issue,
                    onClose: () => setState(() => issue = null),
                    child: const Text('contenido'),
                  ),
                ),
          ),
        ),
      );
      expect(find.text('Sin conexión'), findsOneWidget);
      expect(find.textContaining('No se pudo iniciar la simulación'), findsOneWidget);

      // No desaparece solo (un SnackBar se iría a los 4 s)
      await tester.pump(const Duration(seconds: 30));
      expect(find.textContaining('No se pudo iniciar la simulación'), findsOneWidget);

      await tester.tap(find.text('Reintentar'));
      expect(retries, 1);

      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No se pudo iniciar la simulación'), findsNothing);
      expect(find.text('contenido'), findsOneWidget);
    });

    test('solo dice "Sin conexión" cuando falló la red', () {
      expect(ConnectionIssue.from(const NetworkException('x'), 'm', retry: () {}).offline, isTrue);
      expect(ConnectionIssue.from(const ServerException('x'), 'm', retry: () {}).offline, isFalse);
    });
  });
}
