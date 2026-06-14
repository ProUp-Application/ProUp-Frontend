import 'package:flutter_bloc/flutter_bloc.dart';

import 'chatbot_state.dart';

class ChatbotCubit extends Cubit<ChatbotState> {
  ChatbotCubit() : super(ChatbotState.initial());

  Future<void> sendMessage(String text) async {
    final trimmedText = text.trim();

    if (trimmedText.isEmpty || state.isSending) {
      return;
    }

    final userMessage = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: trimmedText,
      sender: ChatMessageSender.user,
    );

    emit(
      state.copyWith(
        messages: [...state.messages, userMessage],
        status: ChatbotStatus.sending,
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 300));

    emit(
      state.copyWith(
        status: ChatbotStatus.failure,
        errorMessage:
            'El chatbot todavía no se encuentra configurado. Aquí se conectará el endpoint REST de orientación profesional.',
      ),
    );
  }
}