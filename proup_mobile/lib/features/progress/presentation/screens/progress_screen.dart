import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/proup_widgets.dart';
import '../../../../core/widgets/score_indicators.dart';
import '../../../analysis/data/analysis_repository.dart';
import '../../../analysis/data/models/analysis_models.dart';
import '../../../interview/data/interview_repository.dart';
import '../../../interview/data/models/interview_models.dart';

class _ProgressData {
  const _ProgressData(this.analyses, this.interviews, this.stats);

  final List<AnalysisModel> analyses;
  final List<InterviewSimulationModel> interviews;
  final ProgressStats? stats;
}

String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} · '
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Panel de progreso. Los indicadores PERSONALES (solo los del usuario) y la
/// referencia de la COMUNIDAD se muestran separados y con etiquetas explícitas.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => ProgressScreenState();
}

class ProgressScreenState extends State<ProgressScreen> {
  late Future<_ProgressData> _future;
  int _tab = 0; // 0 = imagen, 1 = entrevistas

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ProgressData> _load() async {
    final analysisRepo = getIt<AnalysisRepository>();
    final results = await Future.wait([
      analysisRepo.list(),
      getIt<InterviewRepository>().list().catchError((_) => <InterviewSimulationModel>[]),
      analysisRepo.stats().then<ProgressStats?>((s) => s).catchError((_) => null),
    ]);
    return _ProgressData(
      results[0] as List<AnalysisModel>,
      (results[1] as List<InterviewSimulationModel>).where((s) => s.overallScore != null).toList(),
      results[2] as ProgressStats?,
    );
  }

  /// Recarga los datos (la invoca el shell cada vez que se entra a la pestaña).
  void reload() {
    if (mounted) setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => reload(),
          child: FutureBuilder<_ProgressData>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 80),
                    const Icon(Icons.cloud_off, size: 64, color: AppColors.outlineVariant),
                    const SizedBox(height: 12),
                    const Text('No pudimos cargar tu progreso. Revisa tu conexión.',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Center(child: OutlinedButton(onPressed: reload, child: const Text('Reintentar'))),
                  ],
                );
              }
              final data = snapshot.data!;
              final withResult = data.analyses.where((a) => a.result != null).toList();

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  Text('Tu Evolución', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text('Tus resultados en el tiempo y el historial de todo lo que practicaste.',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 20),
                  if (withResult.isEmpty && data.interviews.isEmpty)
                    const _EmptyState()
                  else ...[
                    if (withResult.isNotEmpty) ...[
                      _PersonalSummaryCard(stats: data.stats, analyses: withResult),
                      const SizedBox(height: 16),
                      _ScoreChartCard(analyses: withResult),
                      const SizedBox(height: 16),
                      _CategoryAveragesCard(analyses: withResult),
                      const SizedBox(height: 16),
                      _CommunityCard(stats: data.stats, latest: withResult.first.overallScore),
                      const SizedBox(height: 24),
                    ],
                    Text('Historial', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    SegmentedButton<int>(
                      segments: [
                        ButtonSegment(value: 0, label: Text('Imagen (${withResult.length})'), icon: const Icon(Icons.photo_camera_outlined)),
                        ButtonSegment(value: 1, label: Text('Entrevistas (${data.interviews.length})'), icon: const Icon(Icons.record_voice_over_outlined)),
                      ],
                      selected: {_tab},
                      onSelectionChanged: (s) => setState(() => _tab = s.first),
                    ),
                    const SizedBox(height: 12),
                    if (_tab == 0)
                      ...(withResult.isEmpty
                          ? [const _EmptyHistory(text: 'Aún no tienes análisis de imagen.')]
                          : withResult.map((a) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _HistoryItem(
                                  icon: Icons.center_focus_strong,
                                  title: a.typeLabel,
                                  subtitle: formatDate(a.createdAt),
                                  score: a.overallScore,
                                  onTap: () => _openAnalysis(a),
                                ),
                              )))
                    else
                      ...(data.interviews.isEmpty
                          ? [const _EmptyHistory(text: 'Aún no completas simulaciones de entrevista.')]
                          : data.interviews.map((s) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _HistoryItem(
                                  icon: Icons.record_voice_over_outlined,
                                  title: 'Entrevista · ${(s.track ?? 'Simulación').split(' · ').first}',
                                  subtitle: s.createdAt == null ? '' : formatDate(s.createdAt!.toLocal()),
                                  score: s.overallScore ?? 0,
                                  onTap: () => context.push(AppRoutes.interviewFeedback, extra: s),
                                ),
                              ))),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openAnalysis(AnalysisModel a) async {
    try {
      // El listado no trae las recomendaciones: se consulta el análisis completo
      final full = await getIt<AnalysisRepository>().getById(a.id);
      if (!mounted) return;
      context.push(AppRoutes.analysisResult, extra: full);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos abrir este análisis. Inténtalo de nuevo.')),
      );
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          const Icon(Icons.insights, size: 80, color: AppColors.outlineVariant),
          const SizedBox(height: 16),
          Text('Aún no tienes resultados.\nAnaliza tu imagen o practica una entrevista para empezar.',
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
      );
}

/// Explicación breve de qué representa un indicador (PRO-03).
class _Explain extends StatelessWidget {
  const _Explain(this.text, {this.light = false});

  final String text;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white.withValues(alpha: 0.85) : AppColors.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 15, color: color),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: color, height: 1.35))),
      ],
    );
  }
}

class _PersonalSummaryCard extends StatelessWidget {
  const _PersonalSummaryCard({required this.stats, required this.analyses});

  final ProgressStats? stats;
  final List<AnalysisModel> analyses;

  @override
  Widget build(BuildContext context) {
    final scores = analyses.map((a) => a.overallScore).toList();
    final latest = stats?.latest ?? scores.first;
    final avg = stats?.average ?? (scores.reduce((a, b) => a + b) / scores.length).round();
    final best = stats?.best ?? scores.reduce((a, b) => a > b ? a : b);

    Widget metric(String label, int value) => Expanded(
          child: Column(
            children: [
              Text('$value', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: scoreColor(value))),
              const SizedBox(height: 2),
              Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        );

    return AmbientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Tus resultados', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              StatusChip(
                label: 'Solo tú',
                background: AppColors.primary.withValues(alpha: 0.1),
                foreground: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(children: [
            metric('Último puntaje', latest),
            metric('Tu promedio', avg),
            metric('Tu mejor', best),
          ]),
          const SizedBox(height: 14),
          _Explain('Puntaje global de imagen (0-100) calculado con tus ${scores.length} análisis. '
              'No incluye resultados de otros usuarios.'),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tu evolución', style: Theme.of(context).textTheme.titleMedium),
                    Text('Tus últimos ${recent.length} análisis', style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
              if (recent.length >= 2)
                Text('${delta >= 0 ? '+' : ''}$delta pts',
                    style: TextStyle(
                        color: delta >= 0 ? AppColors.tertiary : AppColors.error,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < recent.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${recent[i].overallScore}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Flexible(
                            child: FractionallySizedBox(
                              heightFactor: (recent[i].overallScore / 100).clamp(0.05, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: i == recent.length - 1 ? AppColors.primary : AppColors.primaryFixed,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('${recent[i].createdAt.day}/${recent[i].createdAt.month}',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Explain(recent.length >= 2
              ? 'Diferencia en puntos entre tu primer y tu último análisis de este gráfico.'
              : 'Haz otro análisis para ver cómo cambias en el tiempo.'),
        ],
      ),
    );
  }
}

class _CategoryAveragesCard extends StatelessWidget {
  const _CategoryAveragesCard({required this.analyses});

  final List<AnalysisModel> analyses;

  /// Promedio solo de los análisis donde la categoría SÍ se evaluó.
  (int?, int) _avg(int? Function(AnalysisResultModel r) sel) {
    final vals = analyses.map((a) => sel(a.result!)).whereType<int>().toList();
    if (vals.isEmpty) return (null, 0);
    return ((vals.reduce((a, b) => a + b) / vals.length).round(), vals.length);
  }

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Rostro y expresión', _avg((r) => r.faceScore)),
      ('Vestimenta', _avg((r) => r.clothingScore)),
      ('Postura', _avg((r) => r.postureScore)),
      ('Entorno e iluminación', _avg((r) => r.contextScore)),
    ];
    return AmbientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tu promedio por categoría', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final r in rows) ScoreBar(label: '${r.$1} (${r.$2.$2} de ${analyses.length})', score: r.$2.$1),
          const SizedBox(height: 8),
          const _Explain('Entre paréntesis: en cuántos de tus análisis se pudo evaluar cada categoría '
              '(por ejemplo, la postura no se evalúa en una selfie).'),
        ],
      ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard({required this.stats, required this.latest});

  final ProgressStats? stats;
  final int latest;

  @override
  Widget build(BuildContext context) {
    final avg = stats?.communityAverage;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.inverseSurface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Referencia de la comunidad',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              StatusChip(
                label: 'General',
                background: Colors.white.withValues(alpha: 0.15),
                foreground: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (stats == null)
            const Text('No pudimos cargar la referencia de la comunidad.', style: TextStyle(color: Colors.white70))
          else if (avg == null)
            Text(
              'Aún no hay suficientes usuarios para mostrar una referencia (se necesitan al menos ${stats!.minUsers}).',
              style: const TextStyle(color: Colors.white70),
            )
          else ...[
            _bar('Tu último puntaje', latest, 1.0),
            const SizedBox(height: 12),
            _bar('Promedio de ${stats!.communityUsers} usuarios de ProUp', avg, 0.55),
          ],
          const SizedBox(height: 12),
          _Explain(
            '${stats?.communityDescription ?? 'Promedio del último análisis de cada usuario.'} '
            'Sirve como referencia; no es un estándar del mercado laboral.',
            light: true,
          ),
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
            Expanded(child: Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13))),
            Text('$value/100', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(Colors.white.withValues(alpha: opacity)),
          ),
        ),
      ],
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.score,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int score;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AmbientCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          IconBadge(icon: icon, color: AppColors.primary, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
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
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: AppColors.outline),
        ],
      ),
    );
  }
}
