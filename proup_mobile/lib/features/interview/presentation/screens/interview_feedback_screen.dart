import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';

class InterviewFeedbackScreen extends StatelessWidget {
  const InterviewFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(onBack: () => context.go(AppRoutes.interview)),
              const SizedBox(height: 24),
              Text(
                'Feedback de entrevista',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              const Text(
                'Vista preliminar del feedback. Los resultados reales vendrán del backend cuando exista el análisis de entrevista.',
                style: TextStyle(
                  color: Color(0xFF434656),
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              const _OverallScoreCard(),
              const SizedBox(height: 18),
              const _FeedbackMetric(
                title: 'Claridad',
                value: '82',
                description: 'Tus ideas se entienden con buena estructura.',
                icon: Icons.format_quote,
              ),
              const SizedBox(height: 12),
              const _FeedbackMetric(
                title: 'Confianza',
                value: '76',
                description: 'Buen tono general, con espacio para mayor seguridad.',
                icon: Icons.psychology_outlined,
              ),
              const SizedBox(height: 12),
              const _FeedbackMetric(
                title: 'Lenguaje corporal',
                value: '88',
                description: 'Postura abierta y contacto visual consistente.',
                icon: Icons.accessibility_new,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton(
                  onPressed: () => context.go(AppRoutes.dashboard),
                  child: const Text('Volver al dashboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverallScoreCard extends StatelessWidget {
  const _OverallScoreCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF003EC7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Text(
              'Desempeño general',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '82',
            style: TextStyle(
              color: Colors.white,
              fontSize: 52,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackMetric extends StatelessWidget {
  const _FeedbackMetric({
    required this.title,
    required this.value,
    required this.description,
    required this.icon,
  });

  final String title;
  final String value;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD3E4FE)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF003EC7)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0B1C30),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF434656),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF007550),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Volver',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        const Spacer(),
        const Text(
          'ProUp',
          style: TextStyle(
            color: Color(0xFF003EC7),
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}