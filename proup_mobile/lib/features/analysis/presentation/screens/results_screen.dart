import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/proup_widgets.dart';
import '../../../../core/widgets/score_indicators.dart';
import '../../data/analysis_repository.dart';
import '../../data/models/analysis_models.dart';
import '../ondevice/vision_types.dart';

/// Resultado del análisis de imagen: puntajes SOLO de lo visible, con la evidencia
/// que explica cada uno (IMG-07) y lo que no se pudo evaluar y por qué (IMG-03).
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.analysis});

  final AnalysisModel analysis;

  static const categoryLabels = {
    'face': 'Rostro y expresión',
    'clothing': 'Vestimenta',
    'posture': 'Postura',
    'context': 'Entorno e iluminación',
  };

  static const _recCategory = {
    'EXPRESSION': 'face',
    'CLOTHING': 'clothing',
    'POSTURE': 'posture',
    'CONTEXT': 'context',
  };

  static const _recLabels = {
    'CLOTHING': 'Vestimenta',
    'POSTURE': 'Postura',
    'EXPRESSION': 'Expresión',
    'CONTEXT': 'Entorno',
    'SOFT_SKILLS': 'Imagen en conjunto',
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
    final a = result.assessment ?? const AssessmentModel();
    final theme = Theme.of(context);

    // La recomendación clave es la de la categoría evaluada con MENOR puntaje,
    // para que el consejo principal coincida con lo que más hay que mejorar.
    int scoreForRec(RecommendationModel r) {
      final cat = _recCategory[r.category];
      return cat == null ? result.overallScore : (result.scoreOf(cat) ?? 101);
    }

    final recs = [...result.recommendations]
      ..sort((x, y) {
        final byScore = scoreForRec(x).compareTo(scoreForRec(y));
        return byScore != 0 ? byScore : x.priority.compareTo(y.priority);
      });
    final key = recs.where((r) => r.category != 'SOFT_SKILLS').firstOrNull ?? recs.firstOrNull;
    final rest = recs.where((r) => r != key).toList();
    final notEvaluated = a.notEvaluated;

    return Scaffold(
      appBar: AppBar(title: const Text('Tu análisis')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          AmbientCard(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              children: [
                ScoreRing(score: result.overallScore, color: AppColors.primary, size: 160),
                const SizedBox(height: 16),
                Text('Nivel: ${scoreBandLabel(result.overallScore)}', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                if (result.frameType != null)
                  StatusChip(
                    label: 'Foto: ${result.frameType!.label}',
                    background: AppColors.surfaceContainer,
                    foreground: AppColors.primary,
                  ),
                const SizedBox(height: 10),
                Text(
                  notEvaluated.isEmpty
                      ? 'El puntaje global combina las 4 categorías evaluadas.'
                      : 'El puntaje global se calculó solo con lo que se ve en tu foto (${4 - notEvaluated.length} de 4 categorías).',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (key != null) _KeyRecommendation(advice: key.advice, label: _recLabels[key.category] ?? ''),
          const SizedBox(height: 22),

          Text('Desglose y por qué', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Toca una categoría para ver qué observamos en tu foto.', style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          AmbientCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              children: [
                for (final cat in categoryLabels.keys)
                  _CategoryTile(
                    label: categoryLabels[cat]!,
                    score: result.scoreOf(cat),
                    evidence: a.evaluated[cat] ?? const [],
                    notEvaluatedReason: notEvaluated[cat],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _FormalityCard(
            formality: _formalityLabels[result.clothingFormality],
            evidence: a.formalityEvidence,
            clothingEvaluated: result.clothingScore != null,
          ),

          if (notEvaluated.isNotEmpty) ...[
            const SizedBox(height: 16),
            _NotEvaluatedCard(reasons: notEvaluated, frame: result.frameType),
          ],

          if (rest.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Más recomendaciones', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            ...rest.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RecommendationCard(
                    title: _recLabels[r.category] ?? r.category,
                    advice: r.advice,
                    recommendationId: r.id,
                  ),
                )),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.go('/home'),
            child: const Text('Volver al inicio'),
          ),
        ],
      ),
    );
  }
}

class _KeyRecommendation extends StatelessWidget {
  const _KeyRecommendation({required this.advice, required this.label});

  final String advice;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Lo primero a mejorar${label.isEmpty ? '' : ' · $label'}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(advice, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.score,
    required this.evidence,
    required this.notEvaluatedReason,
  });

  final String label;
  final int? score;
  final List<String> evidence;
  final String? notEvaluatedReason;

  @override
  Widget build(BuildContext context) {
    final details = score == null
        ? [notEvaluatedReason ?? 'No se pudo evaluar con esta foto.']
        : evidence;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        title: ScoreBar(label: label, score: score),
        children: [
          if (details.isEmpty)
            Text('Sin detalle disponible para este análisis.', style: Theme.of(context).textTheme.bodySmall)
          else
            ...details.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(score == null ? Icons.visibility_off_outlined : Icons.check_circle_outline,
                          size: 16, color: score == null ? AppColors.outline : AppColors.tertiary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(d, style: Theme.of(context).textTheme.bodySmall)),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

class _FormalityCard extends StatelessWidget {
  const _FormalityCard({required this.formality, required this.evidence, required this.clothingEvaluated});

  final String? formality;
  final List<String> evidence;
  final bool clothingEvaluated;

  @override
  Widget build(BuildContext context) {
    final text = formality == null
        ? (clothingEvaluated
            ? 'No determinada: no se identificaron prendas que permitan valorarla.'
            : 'No determinada: la ropa no se ve en la foto.')
        : evidence.isEmpty
            ? 'Según las prendas identificadas en la foto.'
            : evidence.join(' ');
    return AmbientCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: Icons.checkroom, color: AppColors.tertiaryContainer, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Formalidad: ${formality ?? 'no determinada'}',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(text, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotEvaluatedCard extends StatelessWidget {
  const _NotEvaluatedCard({required this.reasons, required this.frame});

  final Map<String, String> reasons;
  final FrameType? frame;

  @override
  Widget build(BuildContext context) {
    final hint = frame == FrameType.primerPlano
        ? 'Para una evaluación completa, toma una foto de medio cuerpo o de cuerpo entero.'
        : 'Para evaluar todo, toma una foto donde se te vea de cuerpo entero y con buena luz.';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.visibility_off_outlined, color: AppColors.onSurfaceVariant, size: 20),
              const SizedBox(width: 8),
              Text('Qué no pudimos evaluar', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 10),
          for (final e in reasons.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text.rich(TextSpan(children: [
                TextSpan(
                    text: '${ResultsScreen.categoryLabels[e.key] ?? e.key}: ',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: e.value),
              ]), style: Theme.of(context).textTheme.bodySmall),
            ),
          const SizedBox(height: 4),
          Text(hint, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primary)),
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
    } catch (_) {
      if (!mounted) return;
      setState(() => _rating = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se guardó tu calificación. Revisa tu conexión e inténtalo de nuevo.')),
      );
    }
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
                      size: 22,
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
