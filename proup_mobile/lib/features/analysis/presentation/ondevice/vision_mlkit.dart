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
/// 3. Pose Detection  → qué partes del cuerpo se ven (encuadre: primer plano,
///    medio cuerpo o cuerpo completo) y postura REAL: nivel de hombros y
///    verticalidad del torso. Solo se evalúa lo que aparece en la foto.
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
    final imgW = descriptor.width, imgH = descriptor.height;
    final imgArea = (imgW * imgH).toDouble();
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
    // ---------- 3) Cuerpo: qué partes se ven y postura REAL (pose) ----------
    var body = BodyVisibility.none;
    PostureSignals? posture;
    try {
      final poses = await poseDetector.processImage(input);
      if (poses.isNotEmpty) {
        final lm = poses.first.landmarks;
        bool seen(PoseLandmarkType a, PoseLandmarkType b) =>
            ((lm[a]?.likelihood ?? 0) >= 0.5) || ((lm[b]?.likelihood ?? 0) >= 0.5);
        body = BodyVisibility(
          shoulders: seen(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder),
          hips: seen(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip),
          knees: seen(PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee),
          ankles: seen(PoseLandmarkType.leftAnkle, PoseLandmarkType.rightAnkle),
        );
        final ls = lm[PoseLandmarkType.leftShoulder];
        final rs = lm[PoseLandmarkType.rightShoulder];
        final lh = lm[PoseLandmarkType.leftHip];
        final rh = lm[PoseLandmarkType.rightHip];
        if (ls != null && rs != null && body.shoulders) {
          final shoulderWidth = (ls.x - rs.x).abs().clamp(1.0, double.infinity);
          // Hombros nivelados: diferencia vertical relativa al ancho de hombros
          final levelness = (1 - ((ls.y - rs.y).abs() / shoulderWidth)).clamp(0.0, 1.0);
          // Columna vertical: desviación horizontal entre hombros y cadera
          double? verticality;
          if (lh != null && rh != null && body.hips) {
            final midShoulderX = (ls.x + rs.x) / 2, midShoulderY = (ls.y + rs.y) / 2;
            final midHipX = (lh.x + rh.x) / 2, midHipY = (lh.y + rh.y) / 2;
            final dx = (midShoulderX - midHipX).abs();
            final dy = (midShoulderY - midHipY).abs().clamp(1.0, double.infinity);
            verticality = (1 - (dx / dy)).clamp(0.0, 1.0);
          }
          posture = PostureSignals(shoulderLevelness: levelness, torsoVerticality: verticality);
        }
      }
    } catch (_) {/* la pose es opcional: si falla, la postura queda sin evaluar */}

    // En una foto de cuerpo entero el rostro ocupa poco: el mínimo depende del encuadre
    final minFace = body.ankles ? 0.003 : 0.015;
    if (faceRatio < minFace) {
      throw const InvalidImageException(
        'Tu rostro se ve demasiado pequeño en la imagen. Acércate a la cámara e inténtalo de nuevo.',
      );
    }

    final lum = await _luminance(bytes, face.boundingBox, imgW, imgH);
    return scoreVision(VisionSignals(
      smilingProbability: face.smilingProbability,
      leftEyeOpenProbability: face.leftEyeOpenProbability,
      rightEyeOpenProbability: face.rightEyeOpenProbability,
      yaw: face.headEulerAngleY ?? 0,
      roll: face.headEulerAngleZ ?? 0,
      // Luminancia real de la escena: señal objetiva de iluminación
      luminance: lum.scene,
      faceLuminance: lum.face,
      faceRatio: faceRatio,
      labels: labelMap,
      body: body,
      posture: posture,
      requestedCapture: captureType,
    ));
  } finally {
    await faceDetector.close();
    await labeler.close();
    await poseDetector.close();
  }
}

/// Luminancia media (0..1) de toda la imagen y de la zona del rostro, calculada
/// sobre una miniatura de 160 px para que sea rápida en el dispositivo. La del
/// rostro es la señal de iluminación (un fondo claro no es "mala luz").
Future<({double scene, double? face})> _luminance(Uint8List bytes, ui.Rect faceBox, int imgW, int imgH) async {
  try {
    const target = 160;
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: target);
    final frame = await codec.getNextFrame();
    final w = frame.image.width, h = frame.image.height;
    final data = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
    frame.image.dispose();
    if (data == null) return (scene: 0.5, face: null);
    final px = data.buffer.asUint8List();
    // Luma Rec. 709
    double luma(int i) => 0.2126 * px[i] + 0.7152 * px[i + 1] + 0.0722 * px[i + 2];

    double sum = 0;
    int count = 0;
    for (int i = 0; i + 3 < px.length; i += 4) {
      sum += luma(i);
      count++;
    }
    final scene = count == 0 ? 0.5 : (sum / count) / 255.0;

    // Zona central del rostro (60 % del recuadro) para no medir pelo ni fondo
    double? face;
    if (imgW > 0 && imgH > 0) {
      // Fotos de cámara con rotación EXIF: el descriptor puede venir sin rotar
      final rotated = (imgW > imgH) != (w > h) && imgW != imgH;
      final sx = w / (rotated ? imgH : imgW), sy = h / (rotated ? imgW : imgH);
      final cx = faceBox.center.dx * sx, cy = faceBox.center.dy * sy;
      final hw = faceBox.width * sx * 0.3, hh = faceBox.height * sy * 0.3;
      final x0 = (cx - hw).floor().clamp(0, w - 1), x1 = (cx + hw).ceil().clamp(0, w - 1);
      final y0 = (cy - hh).floor().clamp(0, h - 1), y1 = (cy + hh).ceil().clamp(0, h - 1);
      double fs = 0;
      int fc = 0;
      for (int y = y0; y <= y1; y++) {
        for (int x = x0; x <= x1; x++) {
          fs += luma((y * w + x) * 4);
          fc++;
        }
      }
      if (fc >= 4) face = (fs / fc) / 255.0;
    }
    return (scene: scene, face: face);
  } catch (_) {
    return (scene: 0.5, face: null); // ante cualquier fallo, luminancia neutra (no penaliza)
  }
}
