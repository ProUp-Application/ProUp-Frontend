import '../../../core/network/api_client.dart';
import 'models/analysis_models.dart';

class AnalysisRepository {
  AnalysisRepository(this._api);

  final ApiClient _api;

  Future<AnalysisModel> createAnalysis({
    required String captureType,
    required int face,
    required int clothing,
    required int posture,
    required int context,
    String? clothingFormality,
    String? emotionDetected,
  }) async {
    final res = await _api.post('/analysis', data: {
      'captureType': captureType,
      'scores': {'face': face, 'clothing': clothing, 'posture': posture, 'context': context},
      if (clothingFormality != null) 'clothingFormality': clothingFormality,
      if (emotionDetected != null) 'emotionDetected': emotionDetected,
    });
    return AnalysisModel.fromJson((res.data as Map<String, dynamic>)['analysis'] as Map<String, dynamic>);
  }

  Future<List<AnalysisModel>> list() async {
    final res = await _api.get('/analysis');
    final items = (res.data as Map<String, dynamic>)['analyses'] as List<dynamic>? ?? [];
    return items.map((e) => AnalysisModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> sendFeedback({required String recommendationId, required int rating, String? comments}) async {
    await _api.post('/recommendations/$recommendationId/feedback', data: {
      'rating': rating,
      if (comments != null) 'comments': comments,
    });
  }
}
