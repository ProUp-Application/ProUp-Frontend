import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/score_indicators.dart';
import '../../data/analysis_repository.dart';
import '../../data/models/analysis_models.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.analysis});

  final AnalysisModel analysis;

  static const _categoryLabels = {
    'CLOTHING': 'Vestimenta',
    'POSTURE': 'Postura',
    'EXPRESSION': 'Expresión',
    'CONTEXT': 'Entorno',
    'SOFT_SKILLS': 'Habilidades blandas',
  };

  @override
  Widget build(BuildContext context) {
    final result = analysis.result;
    return Scaffold(
      appBar: AppBar(title: const Text('Resultado del análisis')),
      body: result == null
          ? const Center(child: Text('Sin resultado'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(child: ScoreRing(score: result.overallScore)),
                const SizedBox(height: 8),
                Center(
                  child: Text(scoreBandLabel(result.overallScore),
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ScoreBar(label: 'Rostro y expresión', score: result.faceScore),
                        ScoreBar(label: 'Vestimenta', score: result.clothingScore),
                        ScoreBar(label: 'Postura', score: result.postureScore),
                        ScoreBar(label: 'Entorno e iluminación', score: result.contextScore),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Recomendaciones para ti',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                ...result.recommendations.map(
                  (r) => _RecommendationCard(
                    title: _categoryLabels[r.category] ?? r.category,
                    advice: r.advice,
                    recommendationId: r.id,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Volver al inicio'),
                ),
              ],
            ),
    );
  }
}

class _RecommendationCard extends StatefulWidget {
  const _RecommendationCard({
    required this.title,
    required this.advice,
    required this.recommendationId,
  });

  final String title;
  final String advice;
  final String recommendationId;

  @override
  State<_RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<_RecommendationCard> {
  int? _rating;

  Future<void> _rate(int rating) async {
    setState(() => _rating = rating);
    try {
      await getIt<AnalysisRepository>()
          .sendFeedback(recommendationId: widget.recommendationId, rating: rating);
    } catch (_) {/* feedback no crítico */}
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title,
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
            const SizedBox(height: 6),
            Text(widget.advice, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('¿Te fue útil?', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 8),
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _rate(i),
                    icon: Icon(
                      (_rating ?? 0) >= i ? Icons.star : Icons.star_border,
                      size: 20,
                      color: const Color(0xFFE0A100),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
