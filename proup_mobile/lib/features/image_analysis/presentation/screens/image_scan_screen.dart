import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../widgets/camera_preview_placeholder.dart';

class ImageScanScreen extends StatelessWidget {
  const ImageScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(onBack: () => context.go(AppRoutes.dashboard)),
              const SizedBox(height: 24),
              Text(
                'Análisis de imagen profesional',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              const Text(
                'Evalúa tu presencia visual y recibe recomendaciones para proyectar mayor confianza.',
                style: TextStyle(
                  color: Color(0xFF434656),
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              const CameraPreviewPlaceholder(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton.icon(
                  onPressed: () => context.go(AppRoutes.imageAnalysisResult),
                  icon: const Icon(Icons.analytics_outlined),
                  label: const Text('Ver análisis preliminar'),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Cuando el backend esté disponible, esta acción enviará la imagen al servicio REST de análisis.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF737688),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Volver',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        const Spacer(),
        const Text(
          'ProUp',
          style: TextStyle(
            color: Color(0xFF003EC7),
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}