import 'dart:typed_data';

import '../../../core/network/api_client.dart';
import 'cv_models.dart';

/// "Mejorar mi CV". El servidor procesa el CV para responder y no lo guarda.
class CvRepository {
  CvRepository(this._api);

  final ApiClient _api;

  Future<CvDocument> extract(List<int> bytes, String filename) async {
    final res = await _api.postFile('/cv/extract', bytes: bytes, filename: filename);
    return CvDocument.fromJson((res.data as Map<String, dynamic>)['document'] as Map<String, dynamic>);
  }

  Future<CvAnalysis> analyze(CvDocument doc) async {
    final res = await _api.post('/cv/analyze', data: {
      'text': doc.text,
      if (doc.hasTables != null) 'hasTables': doc.hasTables,
      if (doc.hasImages != null) 'hasImages': doc.hasImages,
    });
    return CvAnalysis.fromJson((res.data as Map<String, dynamic>)['analysis'] as Map<String, dynamic>);
  }

  Future<CvImproveResult> improve(String text, {String? targetRole}) async {
    final res = await _api.post('/cv/improve', data: {
      'text': text,
      if (targetRole != null && targetRole.trim().isNotEmpty) 'targetRole': targetRole.trim(),
    });
    return CvImproveResult.fromJson((res.data as Map<String, dynamic>)['result'] as Map<String, dynamic>);
  }

  /// Genera el .docx con el CV revisado y editado por el usuario.
  Future<Uint8List> exportDocx(CvDraft cv) async {
    final bytes = await _api.postForBytes('/cv/docx', data: {'cv': cv.toJson()});
    return Uint8List.fromList(bytes);
  }

  Future<VacancyMatch> match(String cvText, String vacancyText) async {
    final res = await _api.post('/cv/match', data: {'cvText': cvText, 'vacancyText': vacancyText});
    return VacancyMatch.fromJson((res.data as Map<String, dynamic>)['match'] as Map<String, dynamic>);
  }
}
