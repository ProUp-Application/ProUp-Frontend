import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
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
      appBar: AppBar(title: const Text('Mi progreso')),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<List<AnalysisModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.insights, size: 80, color: Color(0xFFB0B4C2)),
                  SizedBox(height: 16),
                  Center(child: Text('Aún no tienes análisis.\n¡Escanea tu imagen para empezar!',
                      textAlign: TextAlign.center)),
                ],
              );
            }

            final scores = items.where((a) => a.result != null).map((a) => a.overallScore).toList();
            final avg = scores.isEmpty ? 0 : (scores.reduce((a, b) => a + b) / scores.length).round();
            final latest = items.first.overallScore;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(child: _StatCard(label: 'Último puntaje', value: latest)),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(label: 'Promedio', value: avg)),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(label: 'Análisis', value: items.length, isScore: false)),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Historial', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                ...items.map((a) => _HistoryTile(analysis: a)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.isScore = true});

  final String label;
  final int value;
  final bool isScore;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text('$value',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: isScore ? scoreColor(value) : AppTheme.primaryColor)),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.analysis});

  final AnalysisModel analysis;

  @override
  Widget build(BuildContext context) {
    final d = analysis.createdAt;
    final date = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    final type = analysis.captureType == 'SELFIE' ? 'Selfie' : 'Cuerpo entero';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scoreColor(analysis.overallScore).withValues(alpha: 0.15),
          child: Text('${analysis.overallScore}',
              style: TextStyle(fontWeight: FontWeight.w700, color: scoreColor(analysis.overallScore))),
        ),
        title: Text(type),
        subtitle: Text(date),
        trailing: Text(scoreBandLabel(analysis.overallScore),
            style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}
