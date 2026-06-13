import 'package:flutter/material.dart';

class RecommendationListItem extends StatelessWidget {
  const RecommendationListItem({
    required this.text,
    super.key,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle,
          color: Color(0xFF007550),
          size: 22,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF434656),
              fontSize: 15,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}