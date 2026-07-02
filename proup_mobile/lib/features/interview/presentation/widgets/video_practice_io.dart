import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../../../core/theme/app_colors.dart';

/// Práctica con video (móvil): muestra la cámara frontal como "self-view"
/// mientras el usuario responde y, cada pocos segundos, analiza ON-DEVICE
/// su comunicación no verbal (presencia, contacto visual, sonrisa).
/// La imagen nunca sale del dispositivo; solo se calcula un puntaje.
class VideoPracticeCard extends StatefulWidget {
  const VideoPracticeCard({super.key, this.onScore});

  /// Recibe el puntaje no verbal acumulado (0-100) cada vez que se actualiza.
  final void Function(int score)? onScore;

  static bool get supported => true;

  @override
  State<VideoPracticeCard> createState() => _VideoPracticeCardState();
}

class _VideoPracticeCardState extends State<VideoPracticeCard> {
  CameraController? _controller;
  Timer? _timer;
  bool _error = false;
  int _samples = 0;
  int _present = 0;
  double _smileSum = 0;
  double _yawSum = 0;
  int? _score;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) throw Exception('sin cámaras');
      final front = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cams.first,
      );
      _controller = CameraController(front, ResolutionPreset.low, enableAudio: false);
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {});
      _timer = Timer.periodic(const Duration(seconds: 6), (_) => _sample());
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  Future<void> _sample() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || c.value.isTakingPicture) return;
    FaceDetector? detector;
    try {
      final shot = await c.takePicture();
      detector = FaceDetector(options: FaceDetectorOptions(enableClassification: true));
      final faces = await detector.processImage(InputImage.fromFilePath(shot.path));
      _samples++;
      if (faces.isNotEmpty) {
        _present++;
        _smileSum += faces.first.smilingProbability ?? 0.4;
        _yawSum += (faces.first.headEulerAngleY ?? 15).abs();
      }
      unawaited(File(shot.path).delete().catchError((_) => File(shot.path)));
      _report();
    } catch (_) {/* muestra fallida: se ignora */} finally {
      await detector?.close();
    }
  }

  void _report() {
    if (_samples == 0) return;
    final presence = _present / _samples;
    final smile = _present > 0 ? (_smileSum / _present).clamp(0.0, 1.0) : 0.3;
    final eyeContact =
        _present > 0 ? (1 - ((_yawSum / _present) / 35)).clamp(0.0, 1.0) : 0.3;
    final score = (presence * 40 + eyeContact * 35 + smile * 25 + 15).round().clamp(20, 98);
    _score = score;
    widget.onScore?.call(score);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'No se pudo iniciar la cámara. Puedes continuar respondiendo por texto.',
          style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
        ),
      );
    }
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.surfaceDim,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        alignment: Alignment.topLeft,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4 > c.value.aspectRatio ? c.value.aspectRatio : 3 / 4,
            child: CameraPreview(c),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration:
                          const BoxDecoration(color: Color(0xFFBA1A1A), shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(
                    _score == null
                        ? 'EN VIVO · analizando…'
                        : 'EN VIVO · no verbal $_score/100',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
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
