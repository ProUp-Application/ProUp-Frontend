import 'package:flutter/material.dart';

enum OnboardingVisualType {
  imageAnalysis,
  interview,
  recommendations,
}

class OnboardingPageData {
  const OnboardingPageData({
    required this.title,
    required this.description,
    required this.visualType,
  });

  final String title;
  final String description;
  final OnboardingVisualType visualType;
}

class OnboardingPageView extends StatelessWidget {
  const OnboardingPageView({
    required this.page,
    super.key,
  });

  final OnboardingPageData page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: _OnboardingVisualCard(type: page.visualType),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0B1C30),
                ),
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.45,
                  color: const Color(0xFF434656),
                ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingVisualCard extends StatelessWidget {
  const _OnboardingVisualCard({
    required this.type,
  });

  final OnboardingVisualType type;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: type == OnboardingVisualType.interview ? 4 / 5 : 1,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF4FF),
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14003EC7),
              blurRadius: 28,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: switch (type) {
            OnboardingVisualType.imageAnalysis => const _ImageAnalysisVisual(),
            OnboardingVisualType.interview => const _InterviewVisual(),
            OnboardingVisualType.recommendations =>
              const _RecommendationsVisual(),
          },
        ),
      ),
    );
  }
}

class _ImageAnalysisVisual extends StatelessWidget {
  const _ImageAnalysisVisual();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _SoftBackground(),
        Center(
          child: Container(
            width: 132,
            height: 132,
            decoration: const BoxDecoration(
              color: Color(0xFFFFFFFF),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x18003EC7),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_search_outlined,
              color: Color(0xFF003EC7),
              size: 72,
            ),
          ),
        ),
        Positioned(
          left: 32,
          right: 32,
          top: 128,
          child: Container(
            height: 2,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0x00003EC7),
                  Color(0xFF003EC7),
                  Color(0x00003EC7),
                ],
              ),
            ),
          ),
        ),
        const Positioned(
          left: 24,
          bottom: 24,
          child: _GlassChip(
            icon: Icons.auto_awesome,
            label: 'Análisis IA',
          ),
        ),
      ],
    );
  }
}

class _InterviewVisual extends StatelessWidget {
  const _InterviewVisual();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        _SoftBackground(),
        Positioned(
          top: 24,
          left: 24,
          right: 24,
          child: _StatusPill(label: 'Analizando contacto visual...'),
        ),
        Center(
          child: Icon(
            Icons.face_6_outlined,
            color: Color(0xFF0B1C30),
            size: 120,
          ),
        ),
        Positioned(
          left: 28,
          right: 28,
          bottom: 116,
          child: _FeedbackCard(
            icon: Icons.visibility_outlined,
            title: 'Excelente contacto',
            description: 'Mantén esta conexión con el reclutador.',
            iconColor: Color(0xFF007550),
            iconBackground: Color(0xFF6FFBBE),
          ),
        ),
        Positioned(
          left: 44,
          right: 28,
          bottom: 32,
          child: _FeedbackCard(
            icon: Icons.person_outline,
            title: 'Postura abierta',
            description: 'Transmites confianza y profesionalismo.',
            iconColor: Color(0xFF003EC7),
            iconBackground: Color(0xFFDDE1FF),
          ),
        ),
      ],
    );
  }
}

class _RecommendationsVisual extends StatelessWidget {
  const _RecommendationsVisual();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        _SoftBackground(),
        Positioned(
          left: 24,
          right: 24,
          top: 44,
          child: _ProgressPreviewCard(),
        ),
        Positioned(
          left: 48,
          right: 20,
          top: 144,
          child: _RecommendationPreviewCard(),
        ),
        Positioned(
          left: 96,
          right: 28,
          bottom: 44,
          child: _TrendPreviewCard(),
        ),
      ],
    );
  }
}

class _SoftBackground extends StatelessWidget {
  const _SoftBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8F9FF),
            Color(0xFFDCE9FF),
          ],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xEFFFFFFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Color(0xFF007550),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF0B1C30),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(
            Icons.videocam_outlined,
            color: Color(0xFF003EC7),
          ),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.iconColor,
    required this.iconBackground,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color iconColor;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xEFFFFFFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0B1C30),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF434656),
                    fontSize: 13,
                    height: 1.2,
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

class _GlassChip extends StatelessWidget {
  const _GlassChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xEFFFFFFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF003EC7), size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF0B1C30),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressPreviewCard extends StatelessWidget {
  const _ProgressPreviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _previewDecoration(),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              fit: StackFit.expand,
              children: const [
                CircularProgressIndicator(
                  value: 0.85,
                  strokeWidth: 5,
                  color: Color(0xFF007550),
                  backgroundColor: Color(0xFFDCE9FF),
                ),
                Center(
                  child: Text(
                    '85%',
                    style: TextStyle(
                      color: Color(0xFF007550),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perfil completado',
                  style: TextStyle(
                    color: Color(0xFF434656),
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '¡Casi listo!',
                  style: TextStyle(
                    color: Color(0xFF0B1C30),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
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

class _RecommendationPreviewCard extends StatelessWidget {
  const _RecommendationPreviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _previewDecoration(),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.tips_and_updates_outlined,
            color: Color(0xFF003EC7),
          ),
          SizedBox(height: 12),
          Text(
            'Mejora tu Elevator Pitch',
            style: TextStyle(
              color: Color(0xFF0B1C30),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Basado en tu última entrevista...',
            style: TextStyle(
              color: Color(0xFF434656),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendPreviewCard extends StatelessWidget {
  const _TrendPreviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _previewDecoration(),
      child: Row(
        children: [
          const Icon(
            Icons.trending_up,
            color: Color(0xFF5C5F61),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: const LinearProgressIndicator(
                value: 0.68,
                minHeight: 8,
                color: Color(0xFF003EC7),
                backgroundColor: Color(0xFFDCE9FF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _previewDecoration() {
  return BoxDecoration(
    color: const Color(0xFFFFFFFF),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0xFFD3E4FE)),
    boxShadow: const [
      BoxShadow(
        color: Color(0x10003EC7),
        blurRadius: 18,
        offset: Offset(0, 10),
      ),
    ],
  );
}