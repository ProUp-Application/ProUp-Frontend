import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

Color scoreColor(int score) {
  if (score < 50) return const Color(0xFFD23B3B);
  if (score < 75) return const Color(0xFFE0A100);
  return AppTheme.tertiaryColor;
}

String scoreBandLabel(int score) {
  if (score < 50) return 'Por mejorar';
  if (score < 75) return 'Bien / Aceptable';
  return 'Profesional';
}

/// Anillo circular con el puntaje global.
class ScoreRing extends StatelessWidget {
  const ScoreRing({super.key, required this.score, this.size = 140});

  final int score;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 12,
              backgroundColor: const Color(0xFFE2E5F0),
              valueColor: AlwaysStoppedAnimation(scoreColor(score)),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$score',
                  style: TextStyle(
                      fontSize: size * 0.3,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textColor)),
              Text('/ 100', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

/// Barra horizontal de un puntaje parcial.
class ScoreBar extends StatelessWidget {
  const ScoreBar({super.key, required this.label, required this.score});

  final String label;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              Text('$score',
                  style: TextStyle(fontWeight: FontWeight.w700, color: scoreColor(score))),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E5F0),
              valueColor: AlwaysStoppedAnimation(scoreColor(score)),
            ),
          ),
        ],
      ),
    );
  }
}
