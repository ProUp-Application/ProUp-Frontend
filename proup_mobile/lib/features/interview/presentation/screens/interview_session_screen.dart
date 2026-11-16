import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/proup_widgets.dart';
import '../../data/interview_repository.dart';
import '../../data/models/interview_models.dart';
import '../interview_timing.dart';
import '../widgets/video_practice_stub.dart'
    if (dart.library.io) '../widgets/video_practice_io.dart';
import '../widgets/voice_answer_panel.dart';

class InterviewSessionScreen extends StatefulWidget {
  const InterviewSessionScreen({super.key, required this.start});

  final InterviewStart start;

  @override
  State<InterviewSessionScreen> createState() => _InterviewSessionScreenState();
}

class _InterviewSessionScreenState extends State<InterviewSessionScreen> {
  late final List<TextEditingController> _controllers;
  late final List<AnswerDraft> _drafts;
  late final DateTime _startedAt;
  final _tts = FlutterTts();
  Timer? _ticker;
  DateTime? _typingSince; // inicio del tiempo escribiendo en la pregunta actual
  int _step = 0;
  double _confidence = 60;
  bool _loading = false;
  bool _videoOn = false;
  bool _recording = false;
  bool _speaking = false;
  bool _ttsReady = false;
  bool _voiceMode = !kIsWeb; // en el teléfono se propone responder hablando
  int? _videoScore; // no verbal medido en vivo (modo video)

  int get _total => widget.start.questions.length;
  int get _limit => widget.start.timeLimitSeconds;
  bool get _isLast => _step == _total - 1;
  bool get _isPitch => widget.start.track.toLowerCase().contains('pitch');
  bool get _hasAnswers => _drafts.any((d) => !d.isEmpty);

  String get _tip {
    final t = widget.start.track.toLowerCase();
    if (_isPitch) {
      return 'Tu pitch debe caber en 60 segundos: gancho inicial, quién eres, tu valor diferencial y un cierre con llamada a la acción.';
    }
    if (t.contains('ejecutiv') || t.contains('presencia')) {
      return 'Proyecta seguridad sin arrogancia: reconoce el contexto, propone con datos y cierra con el siguiente paso.';
    }
    if (t.contains('técnic') || t.contains('tecnic') || t.contains('caso')) {
      return 'Estructura tu razonamiento en voz alta: supuestos → enfoque → solución → trade-offs.';
    }
    return 'Usa el método STAR: Situación, Tarea, Acción y Resultado. Cierra siempre con el resultado concreto y, si puedes, con un número.';
  }

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _controllers = widget.start.questions.map((_) => TextEditingController()).toList();
    _drafts = widget.start.questions.map((_) => AnswerDraft()).toList();
    _initTts();
    // Refresca el temporizador mientras se escribe
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_typingSince != null && mounted) setState(() {});
    });
  }

  Future<void> _initTts() async {
    try {
      for (final lang in ['es-PE', 'es-US', 'es-MX', 'es-ES']) {
        if (await _tts.isLanguageAvailable(lang) == true) {
          await _tts.setLanguage(lang);
          break;
        }
      }
      await _tts.setSpeechRate(0.48);
      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _speaking = false);
      });
      _tts.setCancelHandler(() {
        if (mounted) setState(() => _speaking = false);
      });
      if (mounted) setState(() => _ttsReady = true);
    } catch (_) {/* sin motor de voz: el botón no se muestra */}
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _tts.stop();
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------------- Tiempo escribiendo ----------------

  int get _currentSeconds {
    final d = _drafts[_step];
    final running = _typingSince == null ? 0 : DateTime.now().difference(_typingSince!).inSeconds;
    return d.seconds + running;
  }

  void _pauseTyping() {
    final since = _typingSince;
    if (since != null) {
      _drafts[_step].seconds += DateTime.now().difference(since).inSeconds;
      _typingSince = null;
    }
  }

  void _onTextChanged(String text) {
    _drafts[_step].text = text;
    if (!_voiceMode && text.isNotEmpty && _typingSince == null) _typingSince = DateTime.now();
    if (!_voiceMode) _drafts[_step].mode = 'TEXT';
    setState(() {});
  }

  // ---------------- Navegación ----------------

  Future<void> _goTo(int step) async {
    if (_recording) {
      _snack('Detén la grabación antes de cambiar de pregunta.');
      return;
    }
    _pauseTyping();
    await _tts.stop();
    setState(() {
      _step = step;
      _speaking = false;
    });
  }

  Future<void> _speakQuestion() async {
    if (_speaking) {
      await _tts.stop();
      setState(() => _speaking = false);
      return;
    }
    setState(() => _speaking = true);
    await _tts.speak(widget.start.questions[_step]);
  }

  void _snack(String text) =>
      ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Text(text)));

  Future<bool> _confirmExit() async {
    if (!_hasAnswers || _loading) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Salir de la simulación?'),
        content: const Text('Tus respuestas no se han enviado y se perderán.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Seguir practicando')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salir')),
        ],
      ),
    );
    return leave == true;
  }

  Future<void> _submit() async {
    if (_recording) {
      _snack('Detén la grabación antes de finalizar.');
      return;
    }
    _pauseTyping();
    final responses = <Map<String, dynamic>>[];
    for (var i = 0; i < _total; i++) {
      final d = _drafts[i];
      final answer = _controllers[i].text.trim();
      if (answer.isNotEmpty) {
        responses.add({
          'question': widget.start.questions[i],
          'answer': answer,
          'durationSeconds': d.seconds,
          'mode': d.mode,
        });
      }
    }
    if (responses.isEmpty) {
      _snack('Responde al menos una pregunta, hablando o por escrito.');
      return;
    }
    final unanswered = _total - responses.length;
    if (unanswered > 0) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Finalizar la simulación'),
          content: Text('Te falta responder $unanswered de $_total. Solo se evaluarán las que respondiste.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Seguir respondiendo')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Finalizar')),
          ],
        ),
      );
      if (go != true) return;
    }

    setState(() => _loading = true);
    try {
      final result = await getIt<InterviewRepository>().submit(
        id: widget.start.id,
        responses: responses,
        confidenceScore: _confidence.round(),
        // Solo se envía si se MIDIÓ con la cámara; nunca se reemplaza por la autoevaluación
        nonVerbalScore: _videoScore,
        durationSeconds: DateTime.now().difference(_startedAt).inSeconds,
      );
      if (!mounted) return;
      context.pushReplacement(AppRoutes.interviewFeedback, extra: result);
    } catch (_) {
      if (!mounted) return;
      _snack('No se pudo enviar la entrevista. Revisa tu conexión: tus respuestas siguen aquí.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final question = widget.start.questions[_step];
    final answered = _drafts.where((d) => !d.isEmpty).length;
    final draft = _drafts[_step];
    final used = _currentSeconds;
    final tState = timeState(used, _limit);
    final timerColor = switch (tState) {
      TimeState.onTrack => AppColors.onSurfaceVariant,
      TimeState.closeToLimit => AppColors.scoreMid,
      TimeState.overLimit => AppColors.error,
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmExit() && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Entrevista · ${widget.start.track}')),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (_step + 1) / _total,
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceContainerHigh,
                        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_isPitch ? 'Consigna ${_step + 1} de $_total' : 'Pregunta ${_step + 1} de $_total',
                            style: Theme.of(context).textTheme.labelSmall),
                        Text('$answered respondidas', style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                  children: [
                    if (VideoPracticeCard.supported) ...[
                      Row(
                        children: [
                          const Icon(Icons.videocam_outlined, size: 20, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('Práctica con video (opcional)',
                                style: Theme.of(context).textTheme.titleMedium),
                          ),
                          Switch(value: _videoOn, onChanged: (v) => setState(() => _videoOn = v)),
                        ],
                      ),
                      if (_videoOn) ...[
                        VideoPracticeCard(onScore: (s) => _videoScore = s),
                        const SizedBox(height: 6),
                        Text(
                          'La cámara mide EN tu teléfono la presencia, el contacto visual y la sonrisa; el video no se envía.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 10),
                    ],
                    // Pregunta + escuchar
                    AmbientCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.smart_toy, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text('AI COACH',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2,
                                        color: AppColors.primary)),
                              ),
                              if (_ttsReady)
                                TextButton.icon(
                                  onPressed: _speakQuestion,
                                  icon: Icon(_speaking ? Icons.stop : Icons.volume_up_outlined, size: 18),
                                  label: Text(_speaking ? 'Detener' : 'Escuchar'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(question, style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Modo de respuesta
                    if (!kIsWeb)
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: true, icon: Icon(Icons.mic_none), label: Text('Hablando')),
                          ButtonSegment(value: false, icon: Icon(Icons.keyboard_outlined), label: Text('Escribiendo')),
                        ],
                        selected: {_voiceMode},
                        onSelectionChanged: _recording
                            ? null
                            : (s) {
                                _pauseTyping();
                                setState(() => _voiceMode = s.first);
                              },
                      ),
                    const SizedBox(height: 12),
                    if (_voiceMode && !kIsWeb) ...[
                      VoiceAnswerPanel(
                        key: ValueKey('voz_$_step'),
                        limitSeconds: _limit,
                        isPitch: _isPitch,
                        hasTranscript: draft.mode == 'VOICE' && !draft.isEmpty,
                        onRecordingChanged: (r) => setState(() => _recording = r),
                        onTranscribed: (text, seconds) {
                          setState(() {
                            _controllers[_step].text = text;
                            draft
                              ..text = text
                              ..mode = 'VOICE'
                              ..seconds = seconds;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                    ] else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(Icons.timer_outlined, size: 16, color: timerColor),
                            const SizedBox(width: 6),
                            Text(
                              used == 0
                                  ? 'Tiempo de referencia: ${formatClock(_limit)} (empieza al escribir)'
                                  : timerLabel(used, _limit),
                              style: TextStyle(fontSize: 13, color: timerColor, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    TextField(
                      controller: _controllers[_step],
                      maxLines: 7,
                      minLines: 4,
                      maxLength: 3500,
                      onChanged: _onTextChanged,
                      decoration: InputDecoration(
                        labelText: _voiceMode && draft.mode == 'VOICE'
                            ? 'Transcripción: revísala y corrige lo necesario'
                            : null,
                        hintText: _voiceMode
                            ? 'Aquí aparecerá tu respuesta transcrita…'
                            : (_isPitch ? 'Escribe tu pitch aquí…' : 'Escribe tu respuesta aquí…'),
                      ),
                    ),
                    if (draft.mode == 'VOICE' && !draft.isEmpty)
                      Text('Duración de tu respuesta: ${formatClock(draft.seconds)}',
                          style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TIP DE PROUP',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: AppColors.primary)),
                          const SizedBox(height: 6),
                          Text(_tip, style: Theme.of(context).textTheme.bodySmall),
                          if (_voiceMode) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Evaluamos el contenido de tu respuesta transcrita (qué dices y cómo lo estructuras); '
                              'no evaluamos pronunciación, entonación ni volumen. El audio se usa solo para transcribirlo y no se guarda.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_isLast) ...[
                      const SizedBox(height: 18),
                      Text('¿Qué tan seguro/a te sentiste? (${_confidence.round()})',
                          style: Theme.of(context).textTheme.bodyMedium),
                      Text('Es tu autopercepción: la guardamos en tu historial, pero no cambia tu puntaje.',
                          style: Theme.of(context).textTheme.bodySmall),
                      Slider(
                        value: _confidence,
                        min: 0,
                        max: 100,
                        divisions: 20,
                        label: _confidence.round().toString(),
                        onChanged: (v) => setState(() => _confidence = v),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Row(
                  children: [
                    if (_step > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _loading ? null : () => _goTo(_step - 1),
                          child: const Text('Anterior'),
                        ),
                      ),
                    if (_step > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _loading ? null : (_isLast ? _submit : () => _goTo(_step + 1)),
                        child: _loading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                  SizedBox(width: 10),
                                  Text('Evaluando tus respuestas…'),
                                ],
                              )
                            : Text(_isLast ? 'Finalizar y ver feedback' : 'Siguiente'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
