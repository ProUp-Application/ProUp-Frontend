import '../../presentation/ondevice/vision_types.dart';

class RecommendationModel {
  const RecommendationModel({
    required this.id,
    required this.category,
    required this.description,
    required this.priority,
    this.naturalLanguageAdvice,
    this.applied = false,
  });

  final String id;
  final String category;
  final String description;
  final int priority;
  final String? naturalLanguageAdvice;
  final bool applied;

  String get advice => naturalLanguageAdvice ?? description;

  factory RecommendationModel.fromJson(Map<String, dynamic> json) => RecommendationModel(
        id: json['id'] as String,
        category: json['category'] as String,
        description: json['description'] as String? ?? '',
        priority: json['priority'] as int? ?? 1,
        naturalLanguageAdvice: json['naturalLanguageAdvice'] as String?,
        applied: json['applied'] as bool? ?? false,
      );
}

/// Qué se evaluó (con evidencia visible) y qué no se pudo evaluar y por qué.
class AssessmentModel {
  const AssessmentModel({
    this.evaluated = const {},
    this.notEvaluated = const {},
    this.formalityEvidence = const [],
  });

  /// categoría (face|clothing|posture|context) → evidencia
  final Map<String, List<String>> evaluated;

  /// categoría → motivo
  final Map<String, String> notEvaluated;
  final List<String> formalityEvidence;

  bool get isEmpty => evaluated.isEmpty && notEvaluated.isEmpty;

  static AssessmentModel? fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    final ev = <String, List<String>>{};
    for (final e in (json['evaluated'] as List<dynamic>? ?? [])) {
      final m = e as Map<String, dynamic>;
      ev[m['category'] as String] =
          (m['evidence'] as List<dynamic>? ?? []).map((x) => x.toString()).toList();
    }
    final ne = <String, String>{};
    for (final e in (json['notEvaluated'] as List<dynamic>? ?? [])) {
      final m = e as Map<String, dynamic>;
      ne[m['category'] as String] = m['reason']?.toString() ?? '';
    }
    return AssessmentModel(
      evaluated: ev,
      notEvaluated: ne,
      formalityEvidence:
          (json['formalityEvidence'] as List<dynamic>? ?? []).map((x) => x.toString()).toList(),
    );
  }
}

class AnalysisResultModel {
  const AnalysisResultModel({
    required this.id,
    required this.faceScore,
    required this.clothingScore,
    required this.postureScore,
    required this.contextScore,
    required this.overallScore,
    this.clothingFormality,
    this.emotionDetected,
    this.frameType,
    this.assessment,
    this.recommendations = const [],
    this.analysisMs,
  });

  final String id;
  final int faceScore;

  /// null = no evaluado (no se veía en la foto)
  final int? clothingScore;
  final int? postureScore;
  final int contextScore;
  final int overallScore;
  final String? clothingFormality;
  final String? emotionDetected;
  final FrameType? frameType;
  final AssessmentModel? assessment;
  final List<RecommendationModel> recommendations;

  /// Tiempo que tardó el análisis en el teléfono (ms), si se midió (RNF-01).
  final int? analysisMs;

  /// Puntaje de una categoría por su clave (face|clothing|posture|context).
  int? scoreOf(String category) => switch (category) {
        'face' => faceScore,
        'clothing' => clothingScore,
        'posture' => postureScore,
        'context' => contextScore,
        _ => null,
      };

  factory AnalysisResultModel.fromJson(Map<String, dynamic> json) => AnalysisResultModel(
        id: json['id'] as String,
        faceScore: json['faceScore'] as int? ?? 0,
        clothingScore: json['clothingScore'] as int?,
        postureScore: json['postureScore'] as int?,
        contextScore: json['contextScore'] as int? ?? 0,
        overallScore: json['overallScore'] as int? ?? 0,
        clothingFormality: json['clothingFormality'] as String?,
        emotionDetected: json['emotionDetected'] as String?,
        frameType: FrameType.fromCode(json['frameType'] as String?),
        assessment: AssessmentModel.fromJson(json['assessment']),
        recommendations: (json['recommendations'] as List<dynamic>? ?? [])
            .map((e) => RecommendationModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        analysisMs: switch (json['rawMetrics']) {
          {'analysisMs': final num ms} => ms.round(),
          _ => null,
        },
      );
}

class AnalysisModel {
  const AnalysisModel({
    required this.id,
    required this.captureType,
    required this.status,
    required this.createdAt,
    this.result,
  });

  final String id;
  final String captureType;
  final String status;
  final DateTime createdAt;
  final AnalysisResultModel? result;

  int get overallScore => result?.overallScore ?? 0;

  /// Tipo de análisis para el historial: el encuadre detectado o, en análisis
  /// antiguos, lo que eligió el usuario.
  String get typeLabel {
    final f = result?.frameType;
    if (f != null) return 'Imagen · ${f.label}';
    return captureType == 'SELFIE' ? 'Imagen · Selfie' : 'Imagen · Cuerpo entero';
  }

  factory AnalysisModel.fromJson(Map<String, dynamic> json) => AnalysisModel(
        id: json['id'] as String,
        captureType: json['captureType'] as String? ?? 'SELFIE',
        status: json['status'] as String? ?? 'COMPLETED',
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ?? DateTime.now(),
        result: json['result'] is Map<String, dynamic>
            ? AnalysisResultModel.fromJson(json['result'] as Map<String, dynamic>)
            : null,
      );
}

/// Indicadores del panel de progreso, sin mezclar los del usuario con los generales.
class ProgressStats {
  const ProgressStats({
    required this.analyses,
    this.latest,
    this.average,
    this.best,
    required this.communityUsers,
    this.communityAverage,
    required this.minUsers,
    required this.communityDescription,
  });

  final int analyses;
  final int? latest;
  final int? average;
  final int? best;
  final int communityUsers;

  /// null si aún no hay suficientes usuarios para publicarlo.
  final int? communityAverage;
  final int minUsers;
  final String communityDescription;

  factory ProgressStats.fromJson(Map<String, dynamic> json) {
    final p = json['personal'] as Map<String, dynamic>? ?? {};
    final c = json['community'] as Map<String, dynamic>? ?? {};
    return ProgressStats(
      analyses: p['analyses'] as int? ?? 0,
      latest: p['latest'] as int?,
      average: p['average'] as int?,
      best: p['best'] as int?,
      communityUsers: c['users'] as int? ?? 0,
      communityAverage: c['average'] as int?,
      minUsers: c['minUsers'] as int? ?? 5,
      communityDescription: c['description'] as String? ?? '',
    );
  }
}
