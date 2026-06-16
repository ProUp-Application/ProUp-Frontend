import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/analysis_repository.dart';
import '../ondevice/mock_vision.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _processing = false;

  Future<void> _capture(ImageSource source, String captureType) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 80);
    if (file == null) return;

    setState(() => _processing = true);
    try {
      // 1) Procesamiento ON-DEVICE (la imagen NO se sube)
      final vision = MockOnDeviceVision.analyze(file.path, captureType);

      // 2) Solo se envían los SCORES al backend
      final analysis = await getIt<AnalysisRepository>().createAnalysis(
        captureType: captureType,
        face: vision.face,
        clothing: vision.clothing,
        posture: vision.posture,
        context: vision.context,
        clothingFormality: vision.formality,
        emotionDetected: vision.emotion,
      );

      if (!mounted) return;
      context.push(AppRoutes.analysisResult, extra: analysis);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo completar el análisis')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analizar mi imagen')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.tertiaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, color: AppTheme.tertiaryColor),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tu foto se procesa en tu dispositivo y NO se sube a ningún servidor. Solo se guardan los puntajes.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (_processing) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              Text('Analizando tu imagen…',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium),
            ] else ...[
              Icon(Icons.center_focus_strong,
                  size: 96, color: AppTheme.primaryColor.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              Text('Captura una selfie o foto de cuerpo entero',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
            const Spacer(),
            FilledButton.icon(
              onPressed: _processing ? null : () => _capture(ImageSource.camera, 'SELFIE'),
              icon: const Icon(Icons.photo_camera),
              label: const Text('Tomar selfie (rostro)'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _processing ? null : () => _capture(ImageSource.camera, 'FULL_BODY'),
              icon: const Icon(Icons.accessibility_new),
              label: const Text('Foto de cuerpo entero'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _processing ? null : () => _capture(ImageSource.gallery, 'FULL_BODY'),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Elegir de la galería'),
            ),
          ],
        ),
      ),
    );
  }
}
