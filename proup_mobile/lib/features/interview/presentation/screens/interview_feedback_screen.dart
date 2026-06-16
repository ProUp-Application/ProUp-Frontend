import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/score_indicators.dart';
import '../../data/models/interview_models.dart';

class InterviewFeedbackScreen extends StatelessWidget {
  const InterviewFeedbackScreen({super.key, required this.simulation});

  final InterviewSimulationModel simulation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resultado de la entrevista')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(child: ScoreRing(score: simulation.overallScore ?? 0)),
          const SizedBox(height: 20),
          if ((simulation.feedback ?? '').isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(simulation.feedback!, style: Theme.of(context).textTheme.bodyMedium),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (simulation.strengths.isNotEmpty)
            _Section(
              title: 'Fortalezas',
              color: AppTheme.tertiaryColor,
              icon: Icons.check_circle,
              items: simulation.strengths,
            ),
          if (simulation.improvements.isNotEmpty)
            _Section(
              title: 'Qué mejorar',
              color: const Color(0xFFE0A100),
              icon: Icons.trending_up,
              items: simulation.improvements,
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go('/home'),
            child: const Text('Volver al inicio'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.color, required this.icon, required this.items});

  final String title;
  final Color color;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...items.map(
          (it) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(it, style: Theme.of(context).textTheme.bodyMedium)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
