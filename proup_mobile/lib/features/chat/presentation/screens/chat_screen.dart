import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_colors.dart';
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
      content: '¡Hola! Soy tu coach. ¿En qué puedo ayudarte hoy?',
    ),
  ];
  static const _suggestions = [
    'Tips de vestimenta',
    'Cómo responder preguntas difíciles',
    'Optimizar mi CV',
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

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
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
          id: 'err', role: 'ASSISTANT', content: 'No pude responder ahora. Intenta de nuevo.')));
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
    final showSuggestions = _messages.length <= 1;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                // Cabecera del coach
                Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryContainer.withValues(alpha: 0.1),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 2),
                      ),
                      child: const Icon(Icons.smart_toy, color: AppColors.primary, size: 38),
                    ),
                    const SizedBox(height: 12),
                    Text('AI Coach Advisor', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF4EDEA3), shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text('Siempre disponible', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ..._messages.map((m) => _ChatBubble(message: m)),
                if (showSuggestions) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _suggestions
                        .map((s) => GestureDetector(
                              onTap: () => _send(s),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerHighest.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(s,
                                    style: const TextStyle(
                                        color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                              ),
                            ))
                        .toList(),
                  ),
                ],
                if (_sending)
                  const Padding(
                    padding: EdgeInsets.only(top: 12, left: 44),
                    child: Text('escribiendo…', style: TextStyle(fontSize: 12, color: AppColors.outline)),
                  ),
              ],
            ),
            // Barra de entrada flotante
            Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 32, offset: const Offset(0, 8))],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.add_circle_outline, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          hintText: 'Escribe tu mensaje aquí...',
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton.filled(
                      onPressed: () => _send(),
                      icon: const Icon(Icons.send, size: 20),
                      style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final avatar = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isUser ? AppColors.primary : AppColors.primaryContainer.withValues(alpha: 0.1),
      ),
      child: Icon(isUser ? Icons.person : Icons.smart_toy,
          color: isUser ? Colors.white : AppColors.primary, size: 18),
    );
    final bubble = Flexible(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryContainer : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isUser ? 16 : 2),
            topRight: Radius.circular(isUser ? 2 : 16),
            bottomLeft: const Radius.circular(16),
            bottomRight: const Radius.circular(16),
          ),
        ),
        child: Text(message.content,
            style: TextStyle(color: isUser ? Colors.white : AppColors.onSurface, height: 1.4)),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: isUser ? [bubble, avatar] : [avatar, bubble],
      ),
    );
  }
}
