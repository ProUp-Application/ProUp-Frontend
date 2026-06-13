import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';

class InterviewSessionScreen extends StatelessWidget {
  const InterviewSessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(onClose: () => context.go(AppRoutes.interview)),
              const SizedBox(height: 20),
              const _CameraPanel(),
              const SizedBox(height: 24),
              const Text(
                'Pregunta actual',
                style: TextStyle(
                  color: Color(0xFF434656),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cuéntame sobre ti y por qué te interesa esta oportunidad.',
                style: TextStyle(
                  color: Color(0xFF0B1C30),
                  fontSize: 24,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go(AppRoutes.interview),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => context.go(AppRoutes.interviewFeedback),
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text('Finalizar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraPanel extends StatelessWidget {
  const _CameraPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 420,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF8F9FF), Color(0xFFDCE9FF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          const Center(
            child: Icon(
              Icons.face_6_outlined,
              color: Color(0xFF0B1C30),
              size: 120,
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xEFFFFFFF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                children: [
                  Icon(Icons.circle, color: Color(0xFF007550), size: 12),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Analizando contacto visual y postura...',
                      style: TextStyle(
                        color: Color(0xFF0B1C30),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(Icons.videocam_outlined, color: Color(0xFF003EC7)),
                ],
              ),
            ),
          ),
          const Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: _LiveTipCard(),
          ),
        ],
      ),
    );
  }
}

class _LiveTipCard extends StatelessWidget {
  const _LiveTipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xEFFFFFFF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          Icon(Icons.visibility_outlined, color: Color(0xFF007550)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Buen contacto visual. Mantén respuestas breves y estructuradas.',
              style: TextStyle(
                color: Color(0xFF0B1C30),
                fontSize: 14,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Entrevista',
          style: TextStyle(
            color: Color(0xFF0B1C30),
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Cerrar',
          onPressed: onClose,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}