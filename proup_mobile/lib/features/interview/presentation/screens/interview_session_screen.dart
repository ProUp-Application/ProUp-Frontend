import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/router/app_routes.dart';
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
  double _confidence = 60;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controllers = widget.start.questions.map((_) => TextEditingController()).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final responses = <Map<String, String>>[];
    for (var i = 0; i < widget.start.questions.length; i++) {
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
    return Scaffold(
      appBar: AppBar(title: Text('Entrevista · ${widget.start.track}')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (var i = 0; i < widget.start.questions.length; i++) ...[
            Text('Pregunta ${i + 1}',
                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF003EC7))),
            const SizedBox(height: 4),
            Text(widget.start.questions[i], style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _controllers[i],
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Escribe tu respuesta…'),
            ),
            const SizedBox(height: 20),
          ],
          Text('¿Qué tan seguro/a te sentiste? (${_confidence.round()})',
              style: Theme.of(context).textTheme.bodyMedium),
          Slider(
            value: _confidence,
            min: 0,
            max: 100,
            divisions: 20,
            label: _confidence.round().toString(),
            onChanged: (v) => setState(() => _confidence = v),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Finalizar y ver feedback'),
          ),
        ],
      ),
    );
  }
}
