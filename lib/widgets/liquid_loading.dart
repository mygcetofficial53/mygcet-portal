import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Liquid Fill Loading Animation
/// Creates a premium water-like fill effect inside the logo
class LiquidProgressLoading extends StatefulWidget {
  final double size;
  final Duration duration;
  
  const LiquidProgressLoading({
    super.key,
    this.size = 120,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<LiquidProgressLoading> createState() => _LiquidProgressLoadingState();
}

class _LiquidProgressLoadingState extends State<LiquidProgressLoading>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _fillController;
  late Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();
    
    // Wave animation - continuous smooth wave
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    // Fill animation - fills up then resets
    _fillController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
    
    _fillAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fillController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo with liquid fill effect
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipOval(
            child: Stack(
              children: [
                // Logo image
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/My GCET_20251225_134706_0000.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Text(
                          'MyGCET',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Liquid wave overlay
                AnimatedBuilder(
                  animation: Listenable.merge([_waveController, _fillAnimation]),
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: _LiquidWavePainter(
                        waveProgress: _waveController.value,
                        fillLevel: _fillAnimation.value,
                        color: AppTheme.primaryBlue.withOpacity(0.35),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Animated loading dots
        _AnimatedLoadingDots(),
      ],
    );
  }
}

class _LiquidWavePainter extends CustomPainter {
  final double waveProgress;
  final double fillLevel;
  final Color color;

  _LiquidWavePainter({
    required this.waveProgress,
    required this.fillLevel,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = 8.0;
    final baseY = size.height * (1 - fillLevel);

    path.moveTo(0, size.height);
    path.lineTo(0, baseY);

    // Create smooth wave
    for (double i = 0; i <= size.width; i++) {
      final y = baseY +
          math.sin((i / size.width * 2 * math.pi) + (waveProgress * 2 * math.pi)) *
              waveHeight;
      path.lineTo(i, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Second wave (lighter, slightly offset)
    final paint2 = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, size.height);
    path2.lineTo(0, baseY + 3);

    for (double i = 0; i <= size.width; i++) {
      final y = baseY +
          3 +
          math.sin((i / size.width * 2 * math.pi) +
                  (waveProgress * 2 * math.pi) +
                  math.pi * 0.5) *
              waveHeight *
              0.6;
      path2.lineTo(i, y);
    }

    path2.lineTo(size.width, size.height);
    path2.close();

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant _LiquidWavePainter oldDelegate) {
    return oldDelegate.waveProgress != waveProgress ||
        oldDelegate.fillLevel != fillLevel;
  }
}

/// Animated loading dots
class _AnimatedLoadingDots extends StatefulWidget {
  @override
  State<_AnimatedLoadingDots> createState() => _AnimatedLoadingDotsState();
}

class _AnimatedLoadingDotsState extends State<_AnimatedLoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = ((_controller.value + delay) % 1.0);
            final scale = 0.5 + (math.sin(value * math.pi) * 0.5);
            final opacity = 0.3 + (math.sin(value * math.pi) * 0.7);
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(opacity),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(opacity * 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

/// Simple loading widget for inline use
class LiquidLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;
  
  const LiquidLoadingIndicator({
    super.key,
    this.size = 40,
    this.color,
  });

  @override
  State<LiquidLoadingIndicator> createState() => _LiquidLoadingIndicatorState();
}

class _LiquidLoadingIndicatorState extends State<LiquidLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.primaryBlue;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _CircularLiquidPainter(
            progress: _controller.value,
            color: color,
          ),
        );
      },
    );
  }
}

class _CircularLiquidPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CircularLiquidPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius - 2, bgPaint);

    // Animated arc
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 1.5;
    final startAngle = progress * 2 * math.pi;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularLiquidPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
