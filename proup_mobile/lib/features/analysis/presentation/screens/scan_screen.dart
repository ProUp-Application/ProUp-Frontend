import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/analysis_repository.dart';
import '../ondevice/vision_types.dart';
import '../ondevice/vision_stub.dart' if (dart.library.io) '../ondevice/vision_mlkit.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _scan;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _scan = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() {
    _scan.dispose();
    super.dispose();
  }

  Future<void> _capture(ImageSource source, String captureType) async {
    final file = await ImagePicker().pickImage(source: source, imageQuality: 80);
    if (file == null) return;

    setState(() => _processing = true);
    try {
      // Procesamiento ON-DEVICE: valida que haya una persona y calcula scores
      final vision = await analyzeImage(file.path, captureType);
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
    } on InvalidImageException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFBA1A1A)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No se pudo completar el análisis')));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _openCaptureSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.outlineVariant, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.face_outlined, color: AppColors.primary),
              title: const Text('Tomar selfie (rostro)'),
              onTap: () { Navigator.pop(context); _capture(ImageSource.camera, 'SELFIE'); },
            ),
            ListTile(
              leading: const Icon(Icons.accessibility_new, color: AppColors.primary),
              title: const Text('Foto de cuerpo entero'),
              onTap: () { Navigator.pop(context); _capture(ImageSource.camera, 'FULL_BODY'); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('Elegir de la galería'),
              onTap: () { Navigator.pop(context); _capture(ImageSource.gallery, 'FULL_BODY'); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1430),
      body: Stack(
        children: [
          // "Cámara" simulada (degradado oscuro)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF132445), Color(0xFF0A1430), Color(0xFF06224A)],
              ),
            ),
          ),
          // HUD
          SafeArea(
            child: Column(
              children: [
                // Barra superior
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      const Text('ProUp',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      Icon(Icons.notifications_none, color: Colors.white.withValues(alpha: 0.8)),
                    ],
                  ),
                ),
                const Spacer(),
                // Caja de detección de rostro con chip
                _FaceFrame(scan: _scan),
                const SizedBox(height: 28),
                // Tag de postura
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryContainer.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.tertiary),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFF72FEC0), size: 16),
                      SizedBox(width: 6),
                      Text('Postura correcta',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const Spacer(),
                // Nota de privacidad
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Tu foto se procesa en tu dispositivo y no se sube a ningún servidor.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
                // FAB Analizar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _processing ? null : _openCaptureSheet,
                      icon: _processing
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.sync),
                      label: Text(_processing ? 'ANALIZANDO…' : 'ANALIZAR MI IMAGEN'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaceFrame extends StatelessWidget {
  const _FaceFrame({required this.scan});

  final AnimationController scan;

  @override
  Widget build(BuildContext context) {
    const boxW = 190.0;
    const boxH = 230.0;
    return SizedBox(
      width: boxW,
      height: boxH + 40,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Chip "ROSTRO DETECTADO"
          Positioned(
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.face, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('ROSTRO DETECTADO',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                ],
              ),
            ),
          ),
          // Caja con esquinas
          Positioned(
            top: 36,
            child: SizedBox(
              width: boxW,
              height: boxH,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.5), width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const _Corner(top: true, left: true),
                  const _Corner(top: true, left: false),
                  const _Corner(top: false, left: true),
                  const _Corner(top: false, left: false),
                  // Línea de escaneo animada
                  AnimatedBuilder(
                    animation: scan,
                    builder: (context, _) => Positioned(
                      top: boxH * scan.value,
                      left: 8,
                      right: 8,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Colors.transparent,
                            AppColors.primaryContainer,
                            Colors.transparent,
                          ]),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Text('Analizando vestimenta…',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10, letterSpacing: 1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  const _Corner({required this.top, required this.left});

  final bool top;
  final bool left;

  @override
  Widget build(BuildContext context) {
    const c = AppColors.primary;
    const w = 3.0;
    final border = Border(
      top: top ? const BorderSide(color: c, width: w) : BorderSide.none,
      bottom: !top ? const BorderSide(color: c, width: w) : BorderSide.none,
      left: left ? const BorderSide(color: c, width: w) : BorderSide.none,
      right: !left ? const BorderSide(color: c, width: w) : BorderSide.none,
    );
    return Positioned(
      top: top ? -1 : null,
      bottom: !top ? -1 : null,
      left: left ? -1 : null,
      right: !left ? -1 : null,
      child: Container(width: 18, height: 18, decoration: BoxDecoration(border: border)),
    );
  }
}
