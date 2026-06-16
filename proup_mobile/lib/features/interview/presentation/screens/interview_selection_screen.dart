import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/router/app_routes.dart';
import '../../data/interview_repository.dart';

class InterviewSelectionScreen extends StatefulWidget {
  const InterviewSelectionScreen({super.key});

  @override
  State<InterviewSelectionScreen> createState() => _InterviewSelectionScreenState();
}

class _InterviewSelectionScreenState extends State<InterviewSelectionScreen> {
  static const _tracks = ['Tecnología', 'Finanzas', 'Educación', 'Salud', 'Marketing', 'Creativo'];
  String _selected = _tracks.first;
  bool _loading = false;

  Future<void> _start() async {
    setState(() => _loading = true);
    try {
      final start = await getIt<InterviewRepository>().start(_selected);
      if (!mounted) return;
      context.push(AppRoutes.interviewSession, extra: start);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No se pudo iniciar la simulación')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simulador de entrevistas')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Elige el sector de tu entrevista',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _tracks
                  .map((t) => ChoiceChip(
                        label: Text(t),
                        selected: _selected == t,
                        onSelected: (_) => setState(() => _selected = t),
                      ))
                  .toList(),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _loading ? null : _start,
              child: _loading
                  ? const SizedBox(
                      height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Comenzar simulación'),
            ),
          ],
        ),
      ),
    );
  }
}
