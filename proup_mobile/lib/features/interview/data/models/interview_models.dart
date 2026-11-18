class InterviewStart {
  const InterviewStart({
    required this.id,
    required this.track,
    required this.questions,
    this.timeLimitSeconds = 120,
  });

  final String id;
  final String track;
  final List<String> questions;

  /// Tiempo de referencia por respuesta (60 s en el Elevator Pitch).
  final int timeLimitSeconds;

  factory InterviewStart.fromJson(Map<String, dynamic> json) => InterviewStart(
        id: json['id'] as String,
        track: json['track'] as String? ?? '',
        questions:
            (json['questions'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        timeLimitSeconds: json['timeLimitSeconds'] as int? ??
            ((json['track'] as String? ?? '').toLowerCase().contains('pitch') ? 60 : 120),
      );
}

/// Retroalimentación de una pregunta: contenido, tiempo usado y modo de respuesta.
class QuestionFeedback {
  const QuestionFeedback({
    required this.index,
    required this.question,
    this.score,
    this.feedback,
    this.timeNote,
    this.durationSeconds,
    this.timeLimitSeconds,
    this.mode = 'TEXT',
  });

  final int index;
  final String question;
  final int? score;
  final String? feedback;
  final String? timeNote;
  final int? durationSeconds;
  final int? timeLimitSeconds;
  final String mode;

  bool get isVoice => mode == 'VOICE';

  factory QuestionFeedback.fromJson(Map<String, dynamic> json) => QuestionFeedback(
        index: json['index'] as int? ?? 0,
        question: json['question'] as String? ?? '',
        score: json['score'] as int?,
        feedback: json['feedback'] as String?,
        timeNote: json['timeNote'] as String?,
        durationSeconds: json['durationSeconds'] as int?,
        timeLimitSeconds: json['timeLimitSeconds'] as int?,
        mode: json['mode'] as String? ?? 'TEXT',
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
    this.questionFeedback = const [],
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
  final List<QuestionFeedback> questionFeedback;
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
        questionFeedback: (json['questionFeedback'] as List<dynamic>? ?? [])
            .map((e) => QuestionFeedback.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );
}

/// Respuesta de una pregunta durante la sesión.
class AnswerDraft {
  AnswerDraft();

  String text = '';

  /// VOICE si se grabó y transcribió; TEXT si se escribió.
  String mode = 'TEXT';

  /// Segundos usados para responder (grabación o tiempo escribiendo).
  int seconds = 0;

  bool get isEmpty => text.trim().isEmpty;
}
