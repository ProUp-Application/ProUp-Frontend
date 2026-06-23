import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Logo de ProUp (recreación fiel del SVG del mockup: marca "A" ascendente
/// con punto superior y arco inferior). Dibujado con CustomPaint (sin assets).
class ProupLogo extends StatelessWidget {
  const ProupLogo({super.key, this.size = 48, this.color = AppColors.primaryContainer});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ProupLogoPainter(color)),
    );
  }
}

class _ProupLogoPainter extends CustomPainter {
  _ProupLogoPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Pico (la "A")
    final peak = Path()
      ..moveTo(20 * s, 80 * s)
      ..lineTo(50 * s, 20 * s)
      ..lineTo(80 * s, 80 * s);
    stroke.strokeWidth = 12 * s;
    canvas.drawPath(peak, stroke);

    // Punto superior
    canvas.drawCircle(Offset(50 * s, 20 * s), 8 * s, fill);

    // Arco inferior
    final arch = Path()
      ..moveTo(40 * s, 80 * s)
      ..quadraticBezierTo(50 * s, 60 * s, 60 * s, 80 * s);
    stroke.strokeWidth = 8 * s;
    canvas.drawPath(arch, stroke);
  }

  @override
  bool shouldRepaint(_ProupLogoPainter oldDelegate) => oldDelegate.color != color;
}
