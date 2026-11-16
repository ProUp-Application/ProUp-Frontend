import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/proup_widgets.dart';
import '../../../../core/widgets/score_indicators.dart';
import '../../data/models/interview_models.dart';
import '../interview_timing.dart';

class InterviewFeedbackScreen extends StatelessWidget {
  const InterviewFeedbackScreen({super.key, required this.simulation});

  final InterviewSimulationModel simulation;

  @override
  Widget build(BuildContext context) {
    final score = simulation.overallScore ?? 0;
    // El mensaje acompaña al puntaje: no se felicita un resultado bajo
    final (title, subtitle) = score >= 75
        ? ('¡Muy buen desempeño!', 'Tus respuestas fueron claras y pertinentes. Sigue practicando para mantener el nivel.')
        : score >= 50
            ? ('Vas por buen camino', 'Tienes una buena base. Revisa los comentarios de cada pregunta para dar el siguiente paso.')
            : ('Hay puntos importantes por mejorar', 'Revisa los comentarios de cada pregunta y vuelve a practicar: cada sesión cuenta.');
    return Scaffold(
      appBar: AppBar(title: const Text('Resultado de la entrevista')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const SizedBox(height: 8),
          Center(child: ScoreRing(score: score, color: AppColors.primary, size: 168)),
          const SizedBox(height: 20),
          Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(
            simulation.nonVerbalScore != null
                ? 'Puntaje: 70% contenido de tus respuestas y 30% comunicación no verbal medida con la cámara.'
                : 'Puntaje basado en el contenido de tus respuestas (pertinencia y estructura).',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),

          if (simulation.questionFeedback.isNotEmpty) ...[
            Text('Comentarios por pregunta', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            ...simulation.questionFeedback.map((q) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _QuestionCard(q: q),
                )),
            const SizedBox(height: 10),
          ],

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

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.q});

  final QuestionFeedback q;

  @override
  Widget build(BuildContext context) {
    final limit = q.timeLimitSeconds;
    final dur = q.durationSeconds;
    return AmbientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Pregunta ${q.index}',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
              const Spacer(),
              if (q.score != null)
                Text('${q.score}/100', style: TextStyle(fontWeight: FontWeight.w800, color: scoreColor(q.score!))),
            ],
          ),
          const SizedBox(height: 6),
          Text(q.question, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StatusChip(
                label: q.isVoice ? 'Respondida hablando' : 'Respondida por escrito',
                background: AppColors.surfaceContainer,
                foreground: AppColors.onSurfaceVariant,
              ),
              if (dur != null && dur > 0)
                StatusChip(
                  label: limit == null ? formatClock(dur) : '${formatClock(dur)} de ${formatClock(limit)}',
                  background: (limit != null && dur > limit ? AppColors.error : AppColors.tertiary).withValues(alpha: 0.12),
                  foreground: limit != null && dur > limit ? AppColors.error : AppColors.tertiary,
                ),
            ],
          ),
          if ((q.feedback ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(q.feedback!, style: Theme.of(context).textTheme.bodyMedium),
          ],
          if ((q.timeNote ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: AppColors.scoreMid),
                const SizedBox(width: 6),
                Expanded(child: Text(q.timeNote!, style: Theme.of(context).textTheme.bodySmall)),
              ],
            ),
          ],
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
