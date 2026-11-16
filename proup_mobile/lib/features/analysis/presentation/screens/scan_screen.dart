import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/analysis_repository.dart';
import '../ondevice/vision_types.dart';
import '../ondevice/vision_stub.dart' if (dart.library.io) '../ondevice/vision_mlkit.dart';

/// Opción de captura y lo que permite evaluar (se explica ANTES de tomar la foto).
class _CaptureOption {
  const _CaptureOption({
    required this.icon,
    required this.title,
    required this.evaluates,
    required this.source,
    required this.requested,
  });

  final IconData icon;
  final String title;
  final String evaluates;
  final ImageSource source;

  /// SELFIE | HALF_BODY | FULL_BODY | GALLERY (lo que el usuario pidió)
  final String requested;

  /// El backend solo distingue SELFIE / FULL_BODY; el encuadre real se detecta aparte.
  String get apiCaptureType => requested == 'SELFIE' ? 'SELFIE' : 'FULL_BODY';
}

const _options = [
  _CaptureOption(
    icon: Icons.face_outlined,
    title: 'Selfie o primer plano',
    evaluates: 'Rostro, expresión e iluminación. La ropa solo si se ve el cuello o los hombros.',
    source: ImageSource.camera,
    requested: 'SELFIE',
  ),
  _CaptureOption(
    icon: Icons.person_outline,
    title: 'Medio cuerpo',
    evaluates: 'Además: prenda superior y postura del torso (hombros y cadera a la vista).',
    source: ImageSource.camera,
    requested: 'HALF_BODY',
  ),
  _CaptureOption(
    icon: Icons.accessibility_new,
    title: 'Cuerpo entero',
    evaluates: 'Evaluación completa: vestimenta, postura y entorno. Aléjate hasta que se vean tus pies.',
    source: ImageSource.camera,
    requested: 'FULL_BODY',
  ),
  _CaptureOption(
    icon: Icons.photo_library_outlined,
    title: 'Elegir de la galería',
    evaluates: 'Detectamos el encuadre automáticamente y evaluamos solo lo que aparece.',
    source: ImageSource.gallery,
    requested: 'GALLERY',
  ),
];

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  String? _step; // texto del paso en curso (null = sin procesar)

  bool get _processing => _step != null;

  Future<void> _capture(_CaptureOption option) async {
    final file = await ImagePicker().pickImage(source: option.source, imageQuality: 80);
    if (file == null) return;

    setState(() => _step = 'Analizando tu foto en el teléfono…');
    try {
      // Procesamiento ON-DEVICE: detecta el encuadre y evalúa solo lo visible
      final vision = await analyzeImage(
        file.path,
        option.requested == 'FULL_BODY' ? 'FULL_BODY' : option.requested,
      );

      // Problemas detectados (lentes de sol, gorra, poca luz, rostro girado…):
      // se avisa y se permite repetir la foto ANTES de registrar nada.
      if (vision.issues.isNotEmpty) {
        setState(() => _step = null);
        if (!mounted) return;
        final proceed = await _showIssuesDialog(vision);
        if (proceed != true || !mounted) return;
      }

      setState(() => _step = 'Generando tus recomendaciones…');
      final analysis = await getIt<AnalysisRepository>()
          .createFromVision(vision, captureType: option.apiCaptureType);
      if (!mounted) return;
      context.push(AppRoutes.analysisResult, extra: analysis);
    } on InvalidImageException catch (e) {
      _showError(e.message, retry: option);
    } on AppException catch (e) {
      _showError('${e.message}. Tu foto no se envió; puedes intentarlo de nuevo.', retry: option);
    } catch (_) {
      _showError('No se pudo completar el análisis. Inténtalo de nuevo.', retry: option);
    } finally {
      if (mounted) setState(() => _step = null);
    }
  }

  void _showError(String message, {_CaptureOption? retry}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 6),
        action: retry == null
            ? null
            : SnackBarAction(label: 'Reintentar', textColor: Colors.white, onPressed: () => _capture(retry)),
      ));
  }

  /// Muestra las sugerencias detectadas y pregunta si continuar o repetir la foto.
  Future<bool?> _showIssuesDialog(OnDeviceVisionResult vision) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primary),
            SizedBox(width: 8),
            Expanded(child: Text('Mejora tu foto')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detectamos un ${vision.frameType.label.toLowerCase()} y algunos puntos que pueden afectar tu resultado:'),
            const SizedBox(height: 12),
            ...vision.issues.map((i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  '),
                      Expanded(child: Text(i)),
                    ],
                  ),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver a tomar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Analizar de todos modos'),
          ),
        ],
      ),
    );
  }

  void _openCaptureSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.outlineVariant, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 14),
              Text('¿Qué tipo de foto quieres analizar?', style: Theme.of(sheet).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('Solo evaluamos lo que aparece en la foto.',
                  style: Theme.of(sheet).textTheme.bodySmall),
              const SizedBox(height: 8),
              for (final o in _options)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(o.icon, color: AppColors.primary),
                  title: Text(o.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(o.evaluates, style: const TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.pop(sheet);
                    _capture(o);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1430),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF132445), Color(0xFF0A1430), Color(0xFF06224A)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              const Text('Análisis de imagen',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('Antes de tomar la foto, revisa estas pautas:',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 14)),
              const SizedBox(height: 18),
              const _Tip(icon: Icons.wb_sunny_outlined, text: 'Luz de frente (una ventana o lámpara delante de ti), no a tu espalda.'),
              const _Tip(icon: Icons.crop_portrait, text: 'Fondo limpio y neutro, sin papeles ni pantallas.'),
              const _Tip(icon: Icons.visibility_outlined, text: 'Mira a la cámara, sin lentes de sol ni gorra.'),
              const _Tip(icon: Icons.straighten, text: 'Para evaluar postura y vestimenta, que se vean tus hombros y cadera; para el calzado, también los pies.'),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_outline, color: Color(0xFF72FEC0), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tu foto se procesa en tu teléfono y no se sube a ningún servidor. Solo guardamos los puntajes y la explicación del resultado.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              if (_processing)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                          width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(_step!,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              if (_processing) const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _processing ? null : _openCaptureSheet,
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(_processing ? 'ANALIZANDO…' : 'ANALIZAR MI IMAGEN'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(text,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, height: 1.3)),
            ),
          ),
        ],
      ),
    );
  }
}
