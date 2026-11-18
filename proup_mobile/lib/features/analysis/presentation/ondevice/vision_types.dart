/// Encuadre real de la foto, detectado con los puntos del cuerpo (Pose Detection).
enum FrameType {
  /// Rostro y, como mucho, hombros (selfie).
  primerPlano('PRIMER_PLANO', 'Primer plano'),

  /// De la cintura hacia arriba.
  medioCuerpo('MEDIO_CUERPO', 'Medio cuerpo'),

  /// Persona completa, con piernas y pies visibles.
  cuerpoCompleto('CUERPO_COMPLETO', 'Cuerpo completo');

  const FrameType(this.code, this.label);
  final String code;
  final String label;

  static FrameType? fromCode(String? code) {
    for (final f in FrameType.values) {
      if (f.code == code) return f;
    }
    return null;
  }
}

/// Categoría evaluada y la evidencia VISIBLE que explica su puntaje.
class CategoryEvidence {
  const CategoryEvidence(this.category, this.evidence);

  /// face | clothing | posture | context
  final String category;
  final List<String> evidence;

  Map<String, dynamic> toJson() => {'category': category, 'evidence': evidence};
}

/// Categoría que NO se evaluó y por qué (no se asume lo que no se ve).
class NotEvaluated {
  const NotEvaluated(this.category, this.reason);

  final String category;
  final String reason;

  Map<String, dynamic> toJson() => {'category': category, 'reason': reason};
}

/// Resultado del análisis de visión ON-DEVICE.
class OnDeviceVisionResult {
  const OnDeviceVisionResult({
    required this.frameType,
    required this.face,
    required this.clothing,
    required this.posture,
    required this.context,
    required this.formality,
    required this.emotion,
    this.evaluated = const [],
    this.notEvaluated = const [],
    this.formalityEvidence = const [],
    this.issues = const [],
    this.metrics = const {},
  });

  final FrameType frameType;
  final int face;

  /// null = no se veía la ropa o no se identificaron prendas: no se evalúa.
  final int? clothing;

  /// null = no se veía el cuerpo (hombros y cadera): no se evalúa.
  final int? posture;
  final int context;

  /// FORMAL | SEMI_FORMAL | CASUAL, o null si no hay prendas que lo sustenten.
  final String? formality;
  final String emotion;

  final List<CategoryEvidence> evaluated;
  final List<NotEvaluated> notEvaluated;

  /// Qué elementos visibles sustentan la formalidad asignada.
  final List<String> formalityEvidence;

  /// Problemas detectados que restan profesionalismo (lentes de sol, gorra,
  /// poca luz, rostro girado…). Se muestran al usuario como sugerencias.
  final List<String> issues;

  /// Métricas crudas NO biométricas (ojos abiertos, sonrisa, giro, luminancia…).
  /// Sirven para auditoría/depuración; no reconstruyen el rostro.
  final Map<String, dynamic> metrics;

  /// Tiempo total del análisis en el teléfono (ms), medido en [analyzeImage].
  /// Sirve para verificar el RNF-01 (< 3 s en un equipo de gama media).
  int? get analysisMs => metrics['analysisMs'] as int?;

  /// Copia del resultado con el tiempo de procesamiento en [metrics].
  OnDeviceVisionResult withAnalysisMs(int ms) => OnDeviceVisionResult(
        frameType: frameType,
        face: face,
        clothing: clothing,
        posture: posture,
        context: context,
        formality: formality,
        emotion: emotion,
        evaluated: evaluated,
        notEvaluated: notEvaluated,
        formalityEvidence: formalityEvidence,
        issues: issues,
        metrics: {...metrics, 'analysisMs': ms},
      );

  Map<String, dynamic> assessmentJson() => {
        'evaluated': evaluated.map((e) => e.toJson()).toList(),
        'notEvaluated': notEvaluated.map((e) => e.toJson()).toList(),
        if (formalityEvidence.isNotEmpty) 'formalityEvidence': formalityEvidence,
      };
}

/// Se lanza cuando la imagen no contiene una persona/rostro válido.
class InvalidImageException implements Exception {
  const InvalidImageException(this.message);
  final String message;
}
