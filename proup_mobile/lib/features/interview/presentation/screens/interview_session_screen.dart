import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/proup_widgets.dart';
import '../../data/interview_repository.dart';
import '../../data/models/interview_models.dart';

class InterviewSessionScreen extends StatefulWidget {
  const InterviewSessionScreen({super.key, required this.start});

  final InterviewStart start;

  @override
  State<InterviewSessionScreen> createState() => _InterviewSessionScreenState();
}

class _InterviewSessionScreenState extends State<InterviewSessionScreen> {
  late final List<TextEditingController> _controllers;
  late final DateTime _startedAt;
  int _step = 0;
  double _confidence = 60;
  bool _loading = false;

  int get _total => widget.start.questions.length;
  bool get _isLast => _step == _total - 1;
  bool get _isPitch => widget.start.track.toLowerCase().contains('pitch');

  String get _tip {
    final t = widget.start.track.toLowerCase();
    if (_isPitch) {
      return 'Tu pitch debe caber en 60 segundos: gancho inicial, quién eres, tu valor diferencial y un cierre con llamada a la acción. Practícalo en voz alta y cronométralo.';
    }
    if (t.contains('ejecutiv') || t.contains('presencia')) {
      return 'Proyecta seguridad sin arrogancia: reconoce el contexto, propone con datos y cierra con el siguiente paso. La forma de comunicar pesa tanto como el contenido.';
    }
    if (t.contains('técnic') || t.contains('tecnic') || t.contains('caso')) {
      return 'Estructura tu razonamiento en voz alta: supuestos → enfoque → solución → trade-offs. Un buen proceso vale más que una respuesta memorizada.';
    }
    return 'Usa el método STAR: Situación, Tarea, Acción y Resultado. Cierra siempre con el resultado concreto y, si puedes, con un número.';
  }

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _controllers = widget.start.questions.map((_) => TextEditingController()).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  void _next() {
    if (!_isLast) setState(() => _step++);
  }

  Future<void> _submit() async {
    final responses = <Map<String, String>>[];
    for (var i = 0; i < _total; i++) {
      final answer = _controllers[i].text.trim();
      if (answer.isNotEmpty) {
        responses.add({'question': widget.start.questions[i], 'answer': answer});
      }
    }
    if (responses.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Responde al menos una pregunta')));
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await getIt<InterviewRepository>().submit(
        id: widget.start.id,
        responses: responses,
        confidenceScore: _confidence.round(),
        nonVerbalScore: _confidence.round(),
        durationSeconds: DateTime.now().difference(_startedAt).inSeconds,
      );
      if (!mounted) return;
      context.pushReplacement(AppRoutes.interviewFeedback, extra: result);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No se pudo enviar la entrevista')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.start.questions[_step];
    final answered = _controllers.where((c) => c.text.trim().isNotEmpty).length;

    return Scaffold(
      appBar: AppBar(title: Text('Entrevista · ${widget.start.track}')),
      body: SafeArea(
        child: Column(
          children: [
            // Progreso
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
                      Text(
                          _isPitch
                              ? 'Consigna ${_step + 1} de $_total'
                              : 'Pregunta ${_step + 1} de $_total',
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
                  // Tarjeta del AI Coach con la pregunta
                  AmbientCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryContainer.withValues(alpha: 0.1),
                            border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.2), width: 2),
                          ),
                          child:
                              const Icon(Icons.smart_toy, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('AI COACH',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                      color: AppColors.primary)),
                              const SizedBox(height: 6),
                              Text(question, style: Theme.of(context).textTheme.titleMedium),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Respuesta
                  TextField(
                    controller: _controllers[_step],
                    maxLines: 6,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText:
                          _isPitch ? 'Escribe tu pitch aquí…' : 'Escribe tu respuesta aquí…',
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Tip contextual
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceContainer),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb, color: AppColors.primaryContainer, size: 18),
                            SizedBox(width: 8),
                            Text('TIP DE PROUP',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                    color: AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(_tip, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  if (_isLast) ...[
                    const SizedBox(height: 18),
                    Text('¿Qué tan seguro/a te sentiste en esta simulación? (${_confidence.round()})',
                        style: Theme.of(context).textTheme.bodyMedium),
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
            // Navegación
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _loading ? null : _back,
                        child: const Text('Anterior'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _loading ? null : (_isLast ? _submit : _next),
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(_isLast ? 'Finalizar y ver feedback' : 'Siguiente'),
                    ),
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
