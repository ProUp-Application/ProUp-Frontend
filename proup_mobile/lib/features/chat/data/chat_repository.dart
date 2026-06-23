import '../../../core/network/api_client.dart';
import 'models/chat_models.dart';

class ChatRepository {
  ChatRepository(this._api);

  final ApiClient _api;

  Future<ChatSessionModel> createSession({String? title}) async {
    final res = await _api.post('/chat/sessions', data: {if (title != null) 'title': title});
    return ChatSessionModel.fromJson((res.data as Map<String, dynamic>)['session'] as Map<String, dynamic>);
  }

  Future<List<ChatMessageModel>> getMessages(String sessionId) async {
    final res = await _api.get('/chat/sessions/$sessionId/messages');
    final items = (res.data as Map<String, dynamic>)['messages'] as List<dynamic>? ?? [];
    return items.map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ChatMessageModel> sendMessage(String sessionId, String content) async {
    final res = await _api.post('/chat/sessions/$sessionId/messages', data: {'content': content});
    return ChatMessageModel.fromJson((res.data as Map<String, dynamic>)['message'] as Map<String, dynamic>);
  }
}
