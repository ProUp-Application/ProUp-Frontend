import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/proup_widgets.dart';
import '../../../../core/widgets/score_indicators.dart';
import '../../data/models/interview_models.dart';

class InterviewFeedbackScreen extends StatelessWidget {
  const InterviewFeedbackScreen({super.key, required this.simulation});

  final InterviewSimulationModel simulation;

  @override
  Widget build(BuildContext context) {
    final score = simulation.overallScore ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Resultado de la entrevista')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const SizedBox(height: 8),
          Center(child: ScoreRing(score: score, color: AppColors.primary, size: 168)),
          const SizedBox(height: 20),
          Text('¡Buen desempeño!',
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Estás cada vez más cerca de destacar en tus entrevistas. Sigue practicando.',
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),

          if (simulation.strengths.isNotEmpty) ...[
            _ListCard(
              title: 'Fortalezas',
              icon: Icons.check_circle,
              iconColor: AppColors.tertiary,
              items: simulation.strengths,
            ),
            const SizedBox(height: 14),
          ],
          if (simulation.improvements.isNotEmpty) ...[
            _ListCard(
              title: 'Qué mejorar',
              icon: Icons.trending_up,
              iconColor: AppColors.error,
              items: simulation.improvements,
            ),
            const SizedBox(height: 14),
          ],
          if ((simulation.feedback ?? '').isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('Tip de tu AI Coach',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryContainer.withValues(alpha: 0.2),
                      ),
                      child: const Icon(Icons.sentiment_very_satisfied, color: AppColors.primary, size: 36),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('"${simulation.feedback!}"',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic, color: AppColors.onSurface)),
                ],
              ),
            ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go(AppRoutes.home),
            child: const Text('Volver al inicio'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => context.go(AppRoutes.interview),
            child: const Text('Nueva sesión'),
          ),
        ],
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({required this.title, required this.icon, required this.iconColor, required this.items});

  final String title;
  final IconData icon;
  final Color iconColor;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return AmbientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...items.map(
            (it) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(it, style: Theme.of(context).textTheme.bodyMedium)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
