class InterviewStart {
  const InterviewStart({required this.id, required this.track, required this.questions});

  final String id;
  final String track;
  final List<String> questions;

  factory InterviewStart.fromJson(Map<String, dynamic> json) => InterviewStart(
        id: json['id'] as String,
        track: json['track'] as String? ?? '',
        questions:
            (json['questions'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      );
}

class InterviewSimulationModel {
  const InterviewSimulationModel({
    required this.id,
    this.track,
    this.overallScore,
    this.nonVerbalScore,
    this.confidenceScore,
    this.feedback,
    this.strengths = const [],
    this.improvements = const [],
    this.createdAt,
  });

  final String id;
  final String? track;
  final int? overallScore;
  final int? nonVerbalScore;
  final int? confidenceScore;
  final String? feedback;
  final List<String> strengths;
  final List<String> improvements;
  final DateTime? createdAt;

  static List<String> _strList(dynamic v) =>
      (v as List<dynamic>? ?? []).map((e) => e.toString()).toList();

  factory InterviewSimulationModel.fromJson(Map<String, dynamic> json) =>
      InterviewSimulationModel(
        id: json['id'] as String,
        track: json['track'] as String?,
        overallScore: json['overallScore'] as int?,
        nonVerbalScore: json['nonVerbalScore'] as int?,
        confidenceScore: json['confidenceScore'] as int?,
        feedback: json['feedback'] as String?,
        strengths: _strList(json['strengths']),
        improvements: _strList(json['improvements']),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );
}
