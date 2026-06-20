import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/proup_widgets.dart';
import '../../../../core/widgets/score_indicators.dart';
import '../../../analysis/data/analysis_repository.dart';
import '../../../analysis/data/models/analysis_models.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late Future<List<AnalysisModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = getIt<AnalysisRepository>().list();
  }

  void _reload() => setState(() => _future = getIt<AnalysisRepository>().list());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _reload(),
          child: FutureBuilder<List<AnalysisModel>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = snapshot.data ?? [];
              final withResult = items.where((a) => a.result != null).toList();

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  Text('Tu Evolución', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text('Analizamos tu desempeño para llevar tu carrera al siguiente nivel.',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 24),

                  if (withResult.isEmpty)
                    _EmptyState()
                  else ...[
                    _ScoreChartCard(analyses: withResult),
                    const SizedBox(height: 16),
                    _VsIndustryCard(level: withResult.first.overallScore),
                    const SizedBox(height: 16),
                    _CategoryAveragesCard(analyses: withResult),
                    const SizedBox(height: 24),
                    Text('Historial de Análisis', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    ...items.map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _HistoryItem(analysis: a),
                        )),
                    const SizedBox(height: 12),
                    _ProfileStrengthCard(score: withResult.first.overallScore),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          const Icon(Icons.insights, size: 80, color: AppColors.outlineVariant),
          const SizedBox(height: 16),
          Text('Aún no tienes análisis.\n¡Escanea tu imagen para empezar!',
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ScoreChartCard extends StatelessWidget {
  const _ScoreChartCard({required this.analyses});

  final List<AnalysisModel> analyses;

  @override
  Widget build(BuildContext context) {
    // Últimos 7 análisis, del más antiguo al más reciente
    final recent = analyses.take(7).toList().reversed.toList();
    final delta = recent.length >= 2 ? recent.last.overallScore - recent.first.overallScore : 0;

    return AmbientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Evolución del Puntaje', style: Theme.of(context).textTheme.titleMedium),
                  Text('Últimos análisis', style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
              Text('${delta >= 0 ? '+' : ''}$delta%',
                  style: const TextStyle(color: AppColors.tertiary, fontWeight: FontWeight.w800, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < recent.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FractionallySizedBox(
                        heightFactor: (recent[i].overallScore / 100).clamp(0.05, 1.0),
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          decoration: BoxDecoration(
                            color: i == recent.length - 1
                                ? AppColors.primary
                                : (i == recent.length - 2 ? AppColors.primaryContainer : AppColors.surfaceContainer),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryAveragesCard extends StatelessWidget {
  const _CategoryAveragesCard({required this.analyses});

  final List<AnalysisModel> analyses;

  int _avg(int Function(AnalysisResultModel r) sel) {
    final vals = analyses.where((a) => a.result != null).map((a) => sel(a.result!)).toList();
    if (vals.isEmpty) return 0;
    return (vals.reduce((a, b) => a + b) / vals.length).round();
  }

  @override
  Widget build(BuildContext context) {
    return AmbientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Promedio por categoría', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Tu desempeño promedio en todos tus análisis',
              style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 8),
          ScoreBar(label: 'Rostro y expresión', score: _avg((r) => r.faceScore)),
          ScoreBar(label: 'Vestimenta', score: _avg((r) => r.clothingScore)),
          ScoreBar(label: 'Postura', score: _avg((r) => r.postureScore)),
          ScoreBar(label: 'Entorno e iluminación', score: _avg((r) => r.contextScore)),
        ],
      ),
    );
  }
}

class _VsIndustryCard extends StatelessWidget {
  const _VsIndustryCard({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('VS. Industria',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Comparativa referencial con profesionales en Lima.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14)),
          const SizedBox(height: 20),
          _bar('Tu Nivel', level, 1.0),
          const SizedBox(height: 14),
          _bar('Promedio Global', 72, 0.5),
        ],
      ),
    );
  }

  Widget _bar(String label, int value, double opacity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
            Text('$value/100', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation(Colors.white.withValues(alpha: opacity)),
          ),
        ),
      ],
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.analysis});

  final AnalysisModel analysis;

  @override
  Widget build(BuildContext context) {
    final d = analysis.createdAt;
    final date = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} • '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final type = analysis.captureType == 'SELFIE' ? 'Análisis de Selfie' : 'Análisis de Cuerpo Entero';
    final score = analysis.overallScore;
    return AmbientCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          IconBadge(icon: Icons.center_focus_strong, color: AppColors.primary, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                Text(date, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$score/100',
                  style: TextStyle(fontWeight: FontWeight.w700, color: scoreColor(score), fontSize: 16)),
              const SizedBox(height: 2),
              StatusChip(
                label: scoreBandLabel(score),
                background: scoreColor(score).withValues(alpha: 0.12),
                foreground: scoreColor(score),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileStrengthCard extends StatelessWidget {
  const _ProfileStrengthCard({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fortaleza de Perfil', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 6,
              backgroundColor: AppColors.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation(AppColors.tertiaryContainer),
            ),
          ),
          const SizedBox(height: 10),
          Text('$score% de tu imagen profesional optimizada',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
