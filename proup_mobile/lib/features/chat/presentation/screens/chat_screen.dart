import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/chat_repository.dart';
import '../../data/models/chat_models.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMessageModel> _messages = [
    const ChatMessageModel(
      id: 'welcome',
      role: 'ASSISTANT',
      content:
          '¡Hola! Soy tu asesor ProUp. Puedo ayudarte con entrevistas, imagen profesional y empleabilidad. ¿En qué te ayudo hoy?',
    ),
  ];
  ChatSessionModel? _session;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    try {
      _session = await getIt<ChatRepository>().createSession(title: 'Asesoría');
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    final session = _session;
    if (session == null) return;

    setState(() {
      _messages.add(ChatMessageModel(id: 'u${_messages.length}', role: 'USER', content: text));
      _sending = true;
      _controller.clear();
    });
    _scrollToEnd();

    try {
      final reply = await getIt<ChatRepository>().sendMessage(session.id, text);
      if (!mounted) return;
      setState(() => _messages.add(reply));
    } catch (_) {
      if (!mounted) return;
      setState(() => _messages.add(const ChatMessageModel(
          id: 'err', role: 'ASSISTANT', content: 'No pude responder en este momento. Intenta de nuevo.')));
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asesor IA')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, i) => _Bubble(message: _messages[i]),
              ),
            ),
            if (_sending)
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text('escribiendo…', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(hintText: 'Escribe tu pregunta…'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.content,
          style: TextStyle(color: isUser ? Colors.white : AppTheme.textColor, height: 1.35),
        ),
      ),
    );
  }
}
