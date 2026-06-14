import 'package:flutter/material.dart';

import '../cubit/chatbot_state.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    required this.message,
    super.key,
  });

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == ChatMessageSender.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 310),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF003EC7) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser ? null : Border.all(color: const Color(0xFFD3E4FE)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F003EC7),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : const Color(0xFF0B1C30),
            fontSize: 15,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}