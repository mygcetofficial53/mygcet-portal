import 'package:flutter/material.dart';
import 'dart:math' as math;

class FloatingIconsBackground extends StatefulWidget {
  final Widget child;
  const FloatingIconsBackground({super.key, required this.child});

  @override
  State<FloatingIconsBackground> createState() => _FloatingIconsBackgroundState();
}

class _FloatingIconsBackgroundState extends State<FloatingIconsBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_FloatingIcon> _icons = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Initialize floating icons
    final iconData = [
      Icons.school_outlined,
      Icons.menu_book_rounded,
      Icons.edit_outlined,
      Icons.computer_rounded,
      Icons.science_outlined,
      Icons.calculate_outlined,
      Icons.lightbulb_outline,
      Icons.code_rounded,
    ];

    for (int i = 0; i < 15; i++) {
      _icons.add(_FloatingIcon(
        icon: iconData[_random.nextInt(iconData.length)],
        startPos: Offset(_random.nextDouble(), _random.nextDouble()),
        speed: 0.2 + _random.nextDouble() * 0.5,
        size: 30 + _random.nextDouble() * 40,
        rotationSpeed: (_random.nextBool() ? 1 : -1) * (0.5 + _random.nextDouble()),
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Gradient (Provided by parent or implied)
        
        // Floating Icons
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: _icons.map((icon) {
                 // Calculate new position based on time
                 final t = _controller.value;
                 // Move mainly upwards, slight drift
                 final dy = (icon.startPos.dy - (t * icon.speed)) % 1.2; // Wrap around
                 // Use .2 buffer to start below screen
                 final y = 1.2 - dy; 
                 // Slight horizontal curve
                 final x = (icon.startPos.dx + math.sin(t * 2 * math.pi + icon.startPos.dy) * 0.1) % 1.0;

                 return Positioned(
                   top: y * MediaQuery.of(context).size.height - icon.size, // -size to hide when going off
                   left: x * MediaQuery.of(context).size.width,
                   child: Transform.rotate(
                     angle: t * 2 * math.pi * icon.rotationSpeed,
                     child: Opacity(
                       opacity: 0.1, // Subtle opacity
                       child: Icon(
                         icon.icon,
                         size: icon.size,
                         color: Colors.white,
                       ),
                     ),
                   ),
                 );
              }).toList(),
            );
          },
        ),
        
        // Foreground Content
        widget.child,
      ],
    );
  }
}

class _FloatingIcon {
  final IconData icon;
  final Offset startPos;
  final double speed;
  final double size;
  final double rotationSpeed;

  _FloatingIcon({
    required this.icon,
    required this.startPos,
    required this.speed,
    required this.size,
    required this.rotationSpeed,
  });
}


