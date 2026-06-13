import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../widgets/dashboard_action_card.dart';
import '../widgets/profile_strength_card.dart';
import '../widgets/recommendation_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DashboardHeader(
                onProfileTap: () => context.go(AppRoutes.profile),
              ),
              const SizedBox(height: 28),
              Text(
                'Hola, profesional',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Continúa fortaleciendo tu perfil y prepárate para tu próxima oportunidad.',
                style: TextStyle(
                  color: Color(0xFF434656),
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              const ProfileStrengthCard(progress: 0.72),
              const SizedBox(height: 24),
              Text(
                'Acciones principales',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DashboardActionCard(
                icon: Icons.camera_alt_outlined,
                title: 'Analizar imagen profesional',
                description: 'Evalúa tu presencia visual con apoyo de IA.',
                onTap: () => context.go(AppRoutes.imageAnalysis),
              ),
              const SizedBox(height: 12),
              DashboardActionCard(
                icon: Icons.record_voice_over_outlined,
                title: 'Simular entrevista',
                description: 'Practica respuestas y recibe feedback guiado.',
                onTap: () => context.go(AppRoutes.interview),
              ),
              const SizedBox(height: 12),
              DashboardActionCard(
                icon: Icons.chat_bubble_outline,
                title: 'Consultar al asesor',
                description: 'Resuelve dudas sobre empleabilidad y carrera.',
                onTap: () => context.go(AppRoutes.chatbot),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recomendaciones',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.progress),
                    child: const Text('Ver progreso'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const RecommendationCard(
                label: 'Prioridad alta',
                title: 'Mejora tu presentación personal',
                description:
                    'Completa el análisis de imagen para recibir sugerencias accionables.',
              ),
              const SizedBox(height: 12),
              const RecommendationCard(
                label: 'Siguiente paso',
                title: 'Practica tu elevator pitch',
                description:
                    'Prepara una respuesta breve y clara sobre tu experiencia y objetivos.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.onProfileTap,
  });

  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'ProUp',
          style: TextStyle(
            color: Color(0xFF003EC7),
            fontSize: 30,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Perfil',
          onPressed: onProfileTap,
          icon: const Icon(Icons.person_outline),
        ),
      ],
    );
  }
}