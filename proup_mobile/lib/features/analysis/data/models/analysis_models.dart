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
    this.recommendations = const [],
  });

  final String id;
  final int faceScore;
  final int clothingScore;
  final int postureScore;
  final int contextScore;
  final int overallScore;
  final String? clothingFormality;
  final String? emotionDetected;
  final List<RecommendationModel> recommendations;

  factory AnalysisResultModel.fromJson(Map<String, dynamic> json) => AnalysisResultModel(
        id: json['id'] as String,
        faceScore: json['faceScore'] as int? ?? 0,
        clothingScore: json['clothingScore'] as int? ?? 0,
        postureScore: json['postureScore'] as int? ?? 0,
        contextScore: json['contextScore'] as int? ?? 0,
        overallScore: json['overallScore'] as int? ?? 0,
        clothingFormality: json['clothingFormality'] as String?,
        emotionDetected: json['emotionDetected'] as String?,
        recommendations: (json['recommendations'] as List<dynamic>? ?? [])
            .map((e) => RecommendationModel.fromJson(e as Map<String, dynamic>))
            .toList(),
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

  factory AnalysisModel.fromJson(Map<String, dynamic> json) => AnalysisModel(
        id: json['id'] as String,
        captureType: json['captureType'] as String? ?? 'SELFIE',
        status: json['status'] as String? ?? 'COMPLETED',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        result: json['result'] is Map<String, dynamic>
            ? AnalysisResultModel.fromJson(json['result'] as Map<String, dynamic>)
            : null,
      );
}
