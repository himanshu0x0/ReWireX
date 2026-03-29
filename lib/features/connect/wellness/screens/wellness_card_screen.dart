// ============================================================
// PATH: lib/features/connect/wellness/screens/wellness_card_screen.dart
// ============================================================

import 'package:flutter/material.dart';

class WellnessCard extends StatelessWidget {
  final String emoji, title, sub;
  final Color color;
  final VoidCallback onTap;
  const WellnessCard({super.key, required this.emoji,
      required this.title, required this.sub,
      required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFF141428),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(emoji,
              style: const TextStyle(fontSize: 22)))),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(
            color: Colors.white, fontSize: 15,
            fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(
            color: Colors.white.withOpacity(0.4), fontSize: 12))])));
}