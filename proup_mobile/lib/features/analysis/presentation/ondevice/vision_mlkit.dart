import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'vision_scoring.dart';
import 'vision_types.dart';

/// Pipeline de visión ON-DEVICE real para Android/iOS (3 modelos de ML Kit):
/// 1. Face Detection  → valida que haya una persona real y entrega sonrisa,
///    ojos abiertos (detecta lentes de sol) y orientación de la cabeza.
/// 2. Image Labeling  → valida la ESCENA: rechaza fotos de documentos (DNI,
///    carnets, papeles, pantallas, pósters) y detecta gorras / lentes de sol.
/// 3. Pose Detection  → postura REAL: nivel de hombros y verticalidad de la
///    columna a partir de los landmarks del cuerpo.
/// Los puntajes se calculan en [scoreVision] (vision_scoring.dart).
/// La imagen nunca sale del dispositivo; solo se devuelven puntajes.
Future<OnDeviceVisionResult> analyzeImage(String path, String captureType) async {
  final input = InputImage.fromFilePath(path);
  final faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );
  final labeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.5));
  final poseDetector = PoseDetector(options: PoseDetectorOptions(mode: PoseDetectionMode.single));

  try {
    // ---------- 1) Rostro ----------
    final faces = await faceDetector.processImage(input);
    if (faces.isEmpty) {
      throw const InvalidImageException(
        'No detectamos un rostro en la imagen. Asegúrate de aparecer tú claramente, con buena iluminación.',
      );
    }
    final face = faces.first;

    // ---------- 2) Escena (anti-documento + accesorios) ----------
    final labels = await labeler.processImage(input);
    final labelMap = <String, double>{
      for (final l in labels) l.label.toLowerCase(): l.confidence,
    };

    // Tamaño real de la imagen para calcular la proporción del rostro
    final bytes = await File(path).readAsBytes();
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final imgArea = (descriptor.width * descriptor.height).toDouble();
    descriptor.dispose();
    buffer.dispose();

    final faceArea = face.boundingBox.width * face.boundingBox.height;
    final faceRatio = imgArea > 0 ? faceArea / imgArea : 0.0;

    final docConfidence = labelConfidence(labelMap, documentHints);
    final looksLikePerson =
        (labelMap['selfie'] ?? 0) >= 0.6 || (labelMap['person'] ?? 0) >= 0.75;

    // Un DNI/carnet fotografiado suele: (a) etiquetarse como papel/documento y
    // (b) tener el rostro impreso ocupando una fracción pequeña de la foto.
    if (docConfidence >= 0.55 && faceRatio < 0.30 && !looksLikePerson) {
      throw const InvalidImageException(
        'Parece la foto de un documento o pantalla (por ejemplo, un DNI), no una foto tuya. Tómate una selfie o foto de cuerpo entero real.',
      );
    }
    if (faceRatio < 0.015) {
      throw const InvalidImageException(
        'Tu rostro se ve demasiado pequeño en la imagen. Acércate a la cámara e inténtalo de nuevo.',
      );
    }

    // ---------- 3) Postura REAL (pose) ----------
    int? postureReal;
    try {
      final poses = await poseDetector.processImage(input);
      if (poses.isNotEmpty) {
        final lm = poses.first.landmarks;
        final ls = lm[PoseLandmarkType.leftShoulder];
        final rs = lm[PoseLandmarkType.rightShoulder];
        final lh = lm[PoseLandmarkType.leftHip];
        final rh = lm[PoseLandmarkType.rightHip];
        if (ls != null && rs != null) {
          final shoulderWidth = (ls.x - rs.x).abs().clamp(1.0, double.infinity);
          // Hombros nivelados: diferencia vertical relativa al ancho de hombros
          final levelness = (1 - ((ls.y - rs.y).abs() / shoulderWidth)).clamp(0.0, 1.0);
          // Columna vertical: desviación horizontal entre hombros y cadera
          double verticality = 0.75;
          if (lh != null && rh != null) {
            final midShoulderX = (ls.x + rs.x) / 2, midShoulderY = (ls.y + rs.y) / 2;
            final midHipX = (lh.x + rh.x) / 2, midHipY = (lh.y + rh.y) / 2;
            final dx = (midShoulderX - midHipX).abs();
            final dy = (midShoulderY - midHipY).abs().clamp(1.0, double.infinity);
            verticality = (1 - (dx / dy)).clamp(0.0, 1.0);
          }
          postureReal = (35 + levelness * 35 + verticality * 28).round().clamp(35, 98);
        }
      }
    } catch (_) {/* la pose es opcional: si falla, se usa un valor neutro */}

    return scoreVision(VisionSignals(
      smilingProbability: face.smilingProbability,
      leftEyeOpenProbability: face.leftEyeOpenProbability,
      rightEyeOpenProbability: face.rightEyeOpenProbability,
      yaw: face.headEulerAngleY ?? 0,
      roll: face.headEulerAngleZ ?? 0,
      // Luminancia real de la escena: señal objetiva de iluminación
      luminance: await _averageLuminance(bytes),
      faceRatio: faceRatio,
      labels: labelMap,
      postureReal: postureReal,
    ));
  } finally {
    await faceDetector.close();
    await labeler.close();
    await poseDetector.close();
  }
}

/// Luminancia media (0..1) de la imagen, calculada sobre una miniatura de 64 px
/// para que sea rápida en el dispositivo. Es una señal objetiva de iluminación.
Future<double> _averageLuminance(Uint8List bytes) async {
  try {
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 64);
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
    frame.image.dispose();
    if (data == null) return 0.5;
    final px = data.buffer.asUint8List();
    double sum = 0;
    int count = 0;
    for (int i = 0; i + 3 < px.length; i += 4) {
      // Luma Rec. 709
      sum += 0.2126 * px[i] + 0.7152 * px[i + 1] + 0.0722 * px[i + 2];
      count++;
    }
    if (count == 0) return 0.5;
    return (sum / count) / 255.0;
  } catch (_) {
    return 0.5; // ante cualquier fallo, luminancia neutra (no penaliza)
  }
}
