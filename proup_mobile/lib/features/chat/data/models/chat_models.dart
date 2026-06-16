class ChatSessionModel {
  const ChatSessionModel({required this.id, this.title});

  final String id;
  final String? title;

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) => ChatSessionModel(
        id: json['id'] as String,
        title: json['title'] as String?,
      );
}

class ChatMessageModel {
  const ChatMessageModel({required this.id, required this.role, required this.content});

  final String id;
  final String role; // USER | ASSISTANT | SYSTEM
  final String content;

  bool get isUser => role == 'USER';

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) => ChatMessageModel(
        id: json['id'] as String? ?? '',
        role: json['role'] as String? ?? 'ASSISTANT',
        content: json['content'] as String? ?? '',
      );
}
