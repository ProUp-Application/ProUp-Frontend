import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../cubit/chatbot_cubit.dart';
import '../cubit/chatbot_state.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_message_bubble.dart';

class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatbotCubit(),
      child: const _ChatbotView(),
    );
  }
}

class _ChatbotView extends StatelessWidget {
  const _ChatbotView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatbotCubit, ChatbotState>(
      listener: (context, state) {
        if (state.status == ChatbotStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FF),
          body: Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 20, 12),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Volver',
                        onPressed: () => context.go(AppRoutes.dashboard),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Asesor profesional',
                              style: TextStyle(
                                color: Color(0xFF0B1C30),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Orientación de carrera con IA',
                              style: TextStyle(
                                color: Color(0xFF434656),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDDE1FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.smart_toy_outlined,
                          color: Color(0xFF003EC7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFD3E4FE)),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    return ChatMessageBubble(
                      message: state.messages[index],
                    );
                  },
                ),
              ),
              ChatInputBar(
                isSending: state.isSending,
                onSend: context.read<ChatbotCubit>().sendMessage,
              ),
            ],
          ),
        );
      },
    );
  }
}