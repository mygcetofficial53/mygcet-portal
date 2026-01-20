import 'package:flutter/material.dart';

class AnimatedGradientBackground extends StatelessWidget {
  const AnimatedGradientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // EXACT match to user's screenshot:
    // Top: Soft purple/lavender glow
    // Middle: Purple-gray transition
    // Bottom: Dark slate
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [
                  Color(0xFF9B7BB4), // Soft Lavender (Top)
                  Color(0xFF6B5B7A), // Purple-Gray
                  Color(0xFF3E3654), // Dark Purple
                  Color(0xFF1F1D2B), // Near Black (Bottom)
                ]
              : const [
                  Color(0xFFF8FAFC),
                  Color(0xFFE0C3FC),
                  Color(0xFF8EC5FC),
                  Color(0xFFF8FAFC),
                ],
          stops: const [0.0, 0.3, 0.6, 1.0],
        ),
      ),
    );
  }
}
