import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/proup_widgets.dart';
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

  static const _formalityLabels = {
    'CASUAL': 'Casual',
    'SEMI_FORMAL': 'Semi formal',
    'FORMAL': 'Formal',
  };

  @override
  Widget build(BuildContext context) {
    final result = analysis.result;
    if (result == null) {
      return const Scaffold(body: Center(child: Text('Sin resultado')));
    }

    final recs = [...result.recommendations]..sort((a, b) => a.priority.compareTo(b.priority));
    final key = recs.isNotEmpty ? recs.first : null;
    final rest = recs.length > 1 ? recs.sublist(1) : <RecommendationModel>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Tu análisis')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          // Score hero
          AmbientCard(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Column(
              children: [
                ScoreRing(score: result.overallScore, color: AppColors.primary, size: 168),
                const SizedBox(height: 20),
                Text('Análisis de Desempeño',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text('Nivel: ${scoreBandLabel(result.overallScore)}',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Recomendación clave
          if (key != null)
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.ambientShadow,
                border: const Border(left: BorderSide(color: AppColors.primary, width: 5)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('Recomendación Clave',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('"${key.advice}"', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Tiles
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Puntaje global',
                  value: '${result.overallScore}',
                  background: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  label: 'Formalidad',
                  value: _formalityLabels[result.clothingFormality] ?? '—',
                  background: AppColors.tertiaryContainer,
                  small: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Desglose por categoría
          Text('Desglose', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          AmbientCard(
            child: Column(
              children: [
                ScoreBar(label: 'Rostro y expresión', score: result.faceScore),
                ScoreBar(label: 'Vestimenta', score: result.clothingScore),
                ScoreBar(label: 'Postura', score: result.postureScore),
                ScoreBar(label: 'Entorno e iluminación', score: result.contextScore),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Resto de recomendaciones
          if (rest.isNotEmpty) ...[
            Text('Más recomendaciones', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...rest.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RecommendationCard(
                    title: _categoryLabels[r.category] ?? r.category,
                    advice: r.advice,
                    recommendationId: r.id,
                  ),
                )),
            const SizedBox(height: 8),
          ],

          FilledButton(
            onPressed: () => context.go('/home'),
            child: const Text('Volver al inicio'),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.background,
    this.small = false,
  });

  final String label;
  final String value;
  final Color background;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: Colors.white, fontSize: small ? 20 : 26, fontWeight: FontWeight.w800)),
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
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AmbientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title,
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(height: 6),
          Text(widget.advice, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('¿Te fue útil?', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(width: 8),
              for (var i = 1; i <= 5; i++)
                GestureDetector(
                  onTap: () => _rate(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      (_rating ?? 0) >= i ? Icons.star : Icons.star_border,
                      size: 20,
                      color: AppColors.scoreMid,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
