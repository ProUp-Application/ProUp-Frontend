import 'package:flutter/material.dart';

class CameraPreviewPlaceholder extends StatelessWidget {
  const CameraPreviewPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 430,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFD3E4FE)),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF8F9FF),
                    Color(0xFFDCE9FF),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 156,
              height: 156,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x18003EC7),
                    blurRadius: 28,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_outline,
                color: Color(0xFF003EC7),
                size: 86,
              ),
            ),
          ),
          Positioned(
            top: 32,
            left: 28,
            right: 28,
            child: _ScanLine(),
          ),
          const Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: _CameraHint(),
          ),
        ],
      ),
    );
  }
}

class _ScanLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _CameraHint extends StatelessWidget {
  const _CameraHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xEFFFFFFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.auto_awesome,
            color: Color(0xFF003EC7),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Coloca tu rostro dentro del encuadre para analizar tu imagen profesional.',
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