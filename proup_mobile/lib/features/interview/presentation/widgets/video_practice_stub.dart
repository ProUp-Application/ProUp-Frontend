import 'package:flutter/widgets.dart';

/// Versión web/escritorio: la práctica con video solo está disponible en el
/// build móvil (usa cámara + ML Kit).
class VideoPracticeCard extends StatelessWidget {
  const VideoPracticeCard({super.key, this.onScore});

  final void Function(int score)? onScore;

  static bool get supported => false;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
