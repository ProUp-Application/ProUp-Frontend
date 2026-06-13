import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../widgets/interview_type_card.dart';

class InterviewSelectionScreen extends StatelessWidget {
  const InterviewSelectionScreen({super.key});

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
              _Header(onBack: () => context.go(AppRoutes.dashboard)),
              const SizedBox(height: 24),
              Text(
                'Simulador de entrevista',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              const Text(
                'Elige un escenario de práctica y recibe feedback sobre claridad, seguridad y lenguaje corporal.',
                style: TextStyle(
                  color: Color(0xFF434656),
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              InterviewTypeCard(
                icon: Icons.work_outline,
                title: 'Entrevista laboral',
                description: 'Preguntas frecuentes para posiciones junior y semi senior.',
                onTap: () => context.go(AppRoutes.interviewSession),
              ),
              const SizedBox(height: 14),
              InterviewTypeCard(
                icon: Icons.school_outlined,
                title: 'Prácticas profesionales',
                description: 'Enfocada en primeras experiencias, motivación y potencial.',
                onTap: () => context.go(AppRoutes.interviewSession),
              ),
              const SizedBox(height: 14),
              InterviewTypeCard(
                icon: Icons.record_voice_over_outlined,
                title: 'Elevator pitch',
                description: 'Practica una presentación breve, clara y memorable.',
                onTap: () => context.go(AppRoutes.interviewSession),
              ),
            ],
          ),
        ),
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