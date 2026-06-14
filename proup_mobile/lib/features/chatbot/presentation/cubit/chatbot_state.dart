enum ChatMessageSender {
  user,
  assistant,
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
  });

  final String id;
  final String text;
  final ChatMessageSender sender;
}

enum ChatbotStatus {
  initial,
  sending,
  failure,
}

class ChatbotState {
  const ChatbotState({
    required this.messages,
    this.status = ChatbotStatus.initial,
    this.errorMessage,
  });

  final List<ChatMessage> messages;
  final ChatbotStatus status;
  final String? errorMessage;

  bool get isSending => status == ChatbotStatus.sending;

  ChatbotState copyWith({
    List<ChatMessage>? messages,
    ChatbotStatus? status,
    String? errorMessage,
  }) {
    return ChatbotState(
      messages: messages ?? this.messages,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  factory ChatbotState.initial() {
    return const ChatbotState(
      messages: [
        ChatMessage(
          id: 'welcome',
          text:
              'Hola, soy tu asesor profesional de ProUp.En breve podré responder tus consultas en tiempo real.',
          sender: ChatMessageSender.assistant,
        ),
      ],
    );
  }
}