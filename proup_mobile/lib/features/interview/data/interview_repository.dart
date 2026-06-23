import '../../../core/network/api_client.dart';
import 'models/interview_models.dart';

class InterviewRepository {
  InterviewRepository(this._api);

  final ApiClient _api;

  Future<InterviewStart> start(String track) async {
    final res = await _api.post('/interview/start', data: {'track': track});
    return InterviewStart.fromJson(res.data as Map<String, dynamic>);
  }

  Future<InterviewSimulationModel> submit({
    required String id,
    required List<Map<String, String>> responses,
    int? nonVerbalScore,
    int? confidenceScore,
    int? durationSeconds,
  }) async {
    final res = await _api.post('/interview/$id/submit', data: {
      'responses': responses,
      if (nonVerbalScore != null) 'nonVerbalScore': nonVerbalScore,
      if (confidenceScore != null) 'confidenceScore': confidenceScore,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
    });
    return InterviewSimulationModel.fromJson(
        (res.data as Map<String, dynamic>)['simulation'] as Map<String, dynamic>);
  }

  Future<List<InterviewSimulationModel>> list() async {
    final res = await _api.get('/interview');
    final items = (res.data as Map<String, dynamic>)['simulations'] as List<dynamic>? ?? [];
    return items.map((e) => InterviewSimulationModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
