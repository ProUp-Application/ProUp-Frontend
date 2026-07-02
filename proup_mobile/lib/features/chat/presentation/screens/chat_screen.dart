import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../analysis/data/analysis_repository.dart';
import '../../../analysis/presentation/ondevice/vision_types.dart';
import '../../../analysis/presentation/ondevice/vision_stub.dart'
    if (dart.library.io) '../../../analysis/presentation/ondevice/vision_mlkit.dart';
import '../../data/chat_repository.dart';
import '../../data/models/chat_models.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.onSelectTab});

  /// Permite saltar a otra pestaña del shell (ej. Escanear).
  final void Function(int index)? onSelectTab;

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
          '¡Hola! Soy tu coach ProUp. Conozco tus análisis de imagen y tus entrevistas, así que pregúntame lo que necesites. También puedes tocar el botón + para analizar una foto o revisar tu CV.',
    ),
  ];
  static const _suggestions = [
    '¿Cómo salió mi último análisis?',
    'Tips de vestimenta',
    'Cómo responder preguntas difíciles',
    'Optimizar mi CV',
  ];
  ChatSessionModel? _session;
  bool _sending = false;
  bool _analyzing = false;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    try {
      _session ??= await getIt<ChatRepository>().createSession(title: 'Asesoría');
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

    // Reintenta crear la sesión si falló al abrir la pantalla
    if (_session == null) {
      await _initSession();
      if (_session == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sin conexión con el asesor. Revisa tu internet e intenta de nuevo.')),
        );
        return;
      }
    }
    final session = _session!;

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

  // ---------- Acciones del botón "+" ----------

  void _openAttachSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.outlineVariant, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 6),
            ListTile(
              leading: const Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
              title: const Text('Analizar una foto y pedir consejos'),
              subtitle: const Text('Se procesa en tu dispositivo; el asesor recibe solo los puntajes',
                  style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(sheetContext);
                _analyzePhotoAndAsk();
              },
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined, color: AppColors.primary),
              title: const Text('Revisar mi CV'),
              subtitle: const Text('Pega el texto de tu CV y recibe observaciones',
                  style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(sheetContext);
                _openCvDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.record_voice_over_outlined, color: AppColors.primary),
              title: const Text('Practicar una entrevista'),
              subtitle: const Text('Ir al simulador de entrevistas', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push(AppRoutes.interview);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _analyzePhotoAndAsk() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;

    setState(() => _analyzing = true);
    try {
      // 1) Análisis ON-DEVICE (la foto no se sube)
      final vision = await analyzeImage(file.path, 'FULL_BODY');
      // 2) Se registra el análisis (solo scores) y se generan recomendaciones
      final analysis = await getIt<AnalysisRepository>().createAnalysis(
        captureType: 'FULL_BODY',
        face: vision.face,
        clothing: vision.clothing,
        posture: vision.posture,
        context: vision.context,
        clothingFormality: vision.formality,
        emotionDetected: vision.emotion,
      );
      final r = analysis.result;
      if (!mounted || r == null) return;
      // 3) Se le pregunta al asesor con los resultados reales
      await _send(
        'Acabo de analizar mi imagen en la app. Resultados: global ${r.overallScore}/100, '
        'rostro ${r.faceScore}, vestimenta ${r.clothingScore}, postura ${r.postureScore}, '
        'entorno ${r.contextScore}. ¿Qué debería mejorar primero y cómo?',
      );
    } on InvalidImageException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No se pudo analizar la imagen')));
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  Future<void> _openCvDialog() async {
    final cvController = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Revisar mi CV'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pega el texto de tu CV (o un resumen) y el asesor te dará observaciones.',
                style: TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: cvController,
              maxLines: 8,
              maxLength: 4000,
              decoration: const InputDecoration(hintText: 'Pega aquí el texto de tu CV…'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(dialogContext, cvController.text.trim()),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    cvController.dispose();
    if (text == null || text.isEmpty) return;
    await _send(
        'Por favor revisa este resumen de mi CV y dame recomendaciones concretas para mejorarlo:\n\n$text');
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
                        border:
                            Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 2),
                      ),
                      child: const Icon(Icons.smart_toy, color: AppColors.primary, size: 38),
                    ),
                    const SizedBox(height: 12),
                    Text('AI Coach Advisor', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                            width: 8,
                            height: 8,
                            decoration:
                                const BoxDecoration(color: Color(0xFF4EDEA3), shape: BoxShape.circle)),
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.surfaceContainerHighest.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(s,
                                    style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ))
                        .toList(),
                  ),
                ],
                if (_analyzing)
                  const Padding(
                    padding: EdgeInsets.only(top: 12, left: 44),
                    child: Text('analizando tu imagen…',
                        style: TextStyle(fontSize: 12, color: AppColors.outline)),
                  ),
                if (_sending)
                  const Padding(
                    padding: EdgeInsets.only(top: 12, left: 44),
                    child:
                        Text('escribiendo…', style: TextStyle(fontSize: 12, color: AppColors.outline)),
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
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        blurRadius: 32,
                        offset: const Offset(0, 8))
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _analyzing ? null : _openAttachSheet,
                      icon: const Icon(Icons.add_circle_outline, color: AppColors.secondary),
                      tooltip: 'Adjuntar',
                    ),
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
