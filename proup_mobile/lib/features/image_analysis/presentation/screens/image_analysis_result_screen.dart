import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../widgets/analysis_metric_card.dart';
import '../widgets/recommendation_list_item.dart';

class ImageAnalysisResultScreen extends StatelessWidget {
  const ImageAnalysisResultScreen({super.key});

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
              _Header(onBack: () => context.go(AppRoutes.imageAnalysis)),
              const SizedBox(height: 24),
              Text(
                'Resultados del análisis',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              const Text(
                'Vista preliminar de la pantalla. Los valores reales vendrán del backend cuando el endpoint esté disponible.',
                style: TextStyle(
                  color: Color(0xFF434656),
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              const _ScoreCard(),
              const SizedBox(height: 20),
              const AnalysisMetricCard(
                title: 'Presencia profesional',
                value: '85',
                description: 'Tu imagen transmite seguridad y preparación.',
                icon: Icons.business_center_outlined,
              ),
              const SizedBox(height: 12),
              const AnalysisMetricCard(
                title: 'Lenguaje visual',
                value: '78',
                description: 'Hay oportunidades para mejorar postura y encuadre.',
                icon: Icons.visibility_outlined,
              ),
              const SizedBox(height: 12),
              const AnalysisMetricCard(
                title: 'Confianza proyectada',
                value: '82',
                description: 'Buena expresión facial y contacto con cámara.',
                icon: Icons.sentiment_satisfied_alt,
              ),
              const SizedBox(height: 28),
              Text(
                'Recomendaciones',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const RecommendationListItem(
                text: 'Usa un fondo limpio y bien iluminado para reducir distracciones.',
              ),
              const SizedBox(height: 12),
              const RecommendationListItem(
                text: 'Mantén la cámara a la altura de los ojos para proyectar naturalidad.',
              ),
              const SizedBox(height: 12),
              const RecommendationListItem(
                text: 'Elige vestimenta sobria y alineada al tipo de puesto que buscas.',
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

class _ScoreCard extends StatelessWidget {
  const _ScoreCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF003EC7),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22003EC7),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Score profesional',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Buen punto de partida para entrevistas y networking.',
                  style: TextStyle(
                    color: Color(0xFFDDE1FF),
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
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

class _Header extends StatelessWidget {
  const _Header({
    required this.onBack,
  });

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