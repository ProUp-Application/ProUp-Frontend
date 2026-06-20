import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

Color scoreColor(int score) {
  if (score < 50) return AppColors.scoreLow;
  if (score < 75) return AppColors.scoreMid;
  return AppColors.scoreHigh;
}

String scoreBandLabel(int score) {
  if (score < 50) return 'Por mejorar';
  if (score < 75) return 'Bien / Aceptable';
  return 'Profesional';
}

/// Anillo circular con el puntaje global.
class ScoreRing extends StatelessWidget {
  const ScoreRing({super.key, required this.score, this.size = 150, this.color});

  final int score;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? scoreColor(score);
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
              strokeCap: StrokeCap.round,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation(c),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$score',
                  style: TextStyle(
                      fontSize: size * 0.32,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface)),
              Text('SCORE',
                  style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant)),
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
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation(scoreColor(score)),
            ),
          ),
        ],
      ),
    );
  }
}
