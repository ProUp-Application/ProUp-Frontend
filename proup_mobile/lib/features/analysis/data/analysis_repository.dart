import '../../../core/network/api_client.dart';
import '../presentation/ondevice/vision_types.dart';
import 'models/analysis_models.dart';

class AnalysisRepository {
  AnalysisRepository(this._api);

  final ApiClient _api;

  /// Registra el análisis calculado en el teléfono. Solo viajan puntajes y la
  /// explicación de lo evaluado; la foto nunca sale del dispositivo.
  Future<AnalysisModel> createFromVision(OnDeviceVisionResult v, {required String captureType}) async {
    final res = await _api.post('/analysis', data: {
      'captureType': captureType,
      'frameType': v.frameType.code,
      'scores': {'face': v.face, 'clothing': v.clothing, 'posture': v.posture, 'context': v.context},
      'assessment': v.assessmentJson(),
      if (v.formality != null) 'clothingFormality': v.formality,
      'emotionDetected': v.emotion,
      if (v.metrics.isNotEmpty) 'rawMetrics': v.metrics,
    });
    return AnalysisModel.fromJson((res.data as Map<String, dynamic>)['analysis'] as Map<String, dynamic>);
  }

  Future<List<AnalysisModel>> list() async {
    final res = await _api.get('/analysis');
    final items = (res.data as Map<String, dynamic>)['analyses'] as List<dynamic>? ?? [];
    return items.map((e) => AnalysisModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Análisis completo (con recomendaciones) para reabrirlo desde el historial.
  Future<AnalysisModel> getById(String id) async {
    final res = await _api.get('/analysis/$id');
    return AnalysisModel.fromJson((res.data as Map<String, dynamic>)['analysis'] as Map<String, dynamic>);
  }

  /// Indicadores separados: los del usuario y el promedio de la comunidad.
  Future<ProgressStats> stats() async {
    final res = await _api.get('/analysis/stats');
    return ProgressStats.fromJson((res.data as Map<String, dynamic>)['stats'] as Map<String, dynamic>);
  }

  Future<void> sendFeedback({required String recommendationId, required int rating, String? comments}) async {
    await _api.post('/recommendations/$recommendationId/feedback', data: {
      'rating': rating,
      if (comments != null) 'comments': comments,
    });
  }
}
