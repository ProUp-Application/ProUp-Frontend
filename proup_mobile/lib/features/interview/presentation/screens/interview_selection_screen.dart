import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/proup_widgets.dart';
import '../../data/interview_repository.dart';

class _Track {
  const _Track(this.icon, this.color, this.title, this.desc, this.level, this.skills, this.duration, this.questions);
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  final String level;
  final List<String> skills;
  final String duration;
  final String questions;
}

const _tracks = [
  _Track(Icons.psychology, AppColors.primary, 'Comportamental General',
      'Domina el método STAR y las preguntas de situaciones laborales más comunes.',
      'Principiante', ['Comunicación', 'Resolución'], '15-20 min', '8 preguntas'),
  _Track(Icons.terminal, AppColors.tertiary, 'Técnica / Caso',
      'Practica análisis de lógica, arquitectura o marcos de negocio.',
      'Avanzado', ['Pensamiento analítico', 'Estructura'], '45 min', '3 casos'),
  _Track(Icons.shield, AppColors.primary, 'Presencia Ejecutiva',
      'Enfócate en gravitas, lenguaje corporal y comunicación con stakeholders.',
      'Experto', ['Liderazgo', 'Lenguaje corporal'], '30 min', 'Análisis de video'),
  _Track(Icons.record_voice_over, AppColors.primary, 'Elevator Pitch',
      'Perfecciona tu presentación de 60 segundos para networking o entrevistas.',
      'Cualquiera', ['Concisión', 'Impacto'], '5 min', 'Práctica libre'),
];

class InterviewSelectionScreen extends StatefulWidget {
  const InterviewSelectionScreen({super.key});

  @override
  State<InterviewSelectionScreen> createState() => _InterviewSelectionScreenState();
}

class _InterviewSelectionScreenState extends State<InterviewSelectionScreen> {
  int _selected = 0;
  bool _loading = false;

  Future<void> _start() async {
    setState(() => _loading = true);
    try {
      final start = await getIt<InterviewRepository>().start(_tracks[_selected].title);
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
      appBar: AppBar(title: const Text('ProUp')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text('Elige tu Simulación',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.primary)),
          const SizedBox(height: 6),
          Text('Escoge un track especializado para perfeccionar tu presencia profesional con el coach de IA.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          for (var i = 0; i < _tracks.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _TrackCard(
                track: _tracks[i],
                selected: i == _selected,
                onTap: () => setState(() => _selected = i),
              ),
            ),
          const SizedBox(height: 8),
          // Banner
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Impulsa tu Empleabilidad',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Practicar entrevistas con regularidad aumenta tu confianza y desempeño en las rondas finales.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          top: false,
          child: FilledButton(
            onPressed: _loading ? null : _start,
            child: _loading
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Comenzar Simulación'),
          ),
        ),
      ),
    );
  }
}

class _TrackCard extends StatelessWidget {
  const _TrackCard({required this.track, required this.selected, required this.onTap});

  final _Track track;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceContainerLow : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.ambientShadow,
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBadge(icon: track.icon, color: track.color),
                const Spacer(),
                StatusChip(label: track.level),
                if (selected) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(track.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(track.desc, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: track.skills
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(s, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(track.duration, style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(width: 16),
                const Icon(Icons.list_alt, size: 16, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(track.questions, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
