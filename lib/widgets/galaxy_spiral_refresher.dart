import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Galaxy Spiral Pull-to-Refresh Animation
/// Stars spiraling into a mesmerizing vortex - cosmic aesthetic
class GalaxySpiralRefresher extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final List<Widget> slivers;

  const GalaxySpiralRefresher({
    super.key,
    required this.onRefresh,
    required this.slivers,
  });

  @override
  State<GalaxySpiralRefresher> createState() => _GalaxySpiralRefresherState();
}

class _GalaxySpiralRefresherState extends State<GalaxySpiralRefresher> 
    with SingleTickerProviderStateMixin {
  late AnimationController _spiralController;
  bool _isRefreshing = false;
  final List<_Star> _stars = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _spiralController = AnimationController(
      duration: const Duration(milliseconds: 4000), // Slower rotation
      vsync: this,
    );
    
    // Generate stars
    for (int i = 0; i < 30; i++) {
      _stars.add(_Star(
        angle: _random.nextDouble() * 2 * math.pi,
        distance: 0.3 + _random.nextDouble() * 0.7,
        size: 1.5 + _random.nextDouble() * 3,
        speed: 0.5 + _random.nextDouble() * 0.5,
        color: _getStarColor(),
      ));
    }
  }

  Color _getStarColor() {
    final colors = [
      Colors.white,
      Colors.white70,
      const Color(0xFFE8D5FF),  // Light purple
      const Color(0xFFB8E0FF),  // Light blue
      const Color(0xFFFFE8D5),  // Light yellow
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _spiralController.dispose();
    super.dispose();
  }

  void _startAnimation() {
    if (!_isRefreshing) {
      _isRefreshing = true;
      Future.delayed(const Duration(milliseconds: 200), () { // Slight delay
        if (mounted) {
          _spiralController.repeat();
        }
      });
    }
  }

  void _stopAnimation() {
    _isRefreshing = false;
    _spiralController.stop();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            _startAnimation();
            await widget.onRefresh();
            _stopAnimation();
            HapticFeedback.lightImpact();
          },
          builder: (context, refreshState, pulledExtent, refreshTriggerPullDistance, refreshIndicatorExtent) {
            final double percentage = (pulledExtent / refreshTriggerPullDistance).clamp(0.0, 1.0);
            
            if (refreshState == RefreshIndicatorMode.refresh && !_isRefreshing) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _startAnimation());
            }
            
            return _buildGalaxyHeader(
              context, 
              pulledExtent, 
              refreshState, 
              percentage,
            );
          },
        ),
        ...widget.slivers,
      ],
    );
  }

  Widget _buildGalaxyHeader(
    BuildContext context,
    double pulledExtent,
    RefreshIndicatorMode refreshState,
    double percentage,
  ) {
    if (pulledExtent <= 1) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white70 : Colors.black54;
    final Color coreColor = isDark 
        ? const Color(0xFF9C27B0)  // Purple
        : const Color(0xFF3F51B5); // Indigo

    return Container(
      height: pulledExtent,
      width: double.infinity,
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Galaxy spiral with stars
          AnimatedBuilder(
            animation: _spiralController,
            builder: (context, child) {
              return CustomPaint(
                size: Size(pulledExtent * 2, pulledExtent),
                painter: _GalaxyPainter(
                  stars: _stars,
                  progress: refreshState == RefreshIndicatorMode.refresh
                      ? _spiralController.value
                      : percentage * 0.3,
                  pullPercentage: percentage,
                  coreColor: coreColor,
                  isDark: isDark,
                ),
              );
            },
          ),
          
          // Core glow
          Container(
            width: 20 + (percentage * 15),
            height: 20 + (percentage * 15),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  coreColor.withOpacity(0.8),
                  coreColor.withOpacity(0.3),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: coreColor.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
          
          // Status Text
          Positioned(
            bottom: 10,
            child: Opacity(
              opacity: percentage * 0.9,
              child: Text(
                refreshState == RefreshIndicatorMode.armed 
                    ? "Release" 
                    : refreshState == RefreshIndicatorMode.refresh 
                        ? "✨ Syncing..." 
                        : "Pull down",
                style: TextStyle(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Star {
  final double angle;
  final double distance;
  final double size;
  final double speed;
  final Color color;

  _Star({
    required this.angle,
    required this.distance,
    required this.size,
    required this.speed,
    required this.color,
  });
}

class _GalaxyPainter extends CustomPainter {
  final List<_Star> stars;
  final double progress;
  final double pullPercentage;
  final Color coreColor;
  final bool isDark;

  _GalaxyPainter({
    required this.stars,
    required this.progress,
    required this.pullPercentage,
    required this.coreColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.45;

    // Draw spiral arms (subtle)
    _drawSpiralArms(canvas, center, maxRadius);

    // Draw stars
    for (final star in stars) {
      final starProgress = (progress * star.speed) % 1.0;
      
      // Spiral motion: stars move inward as they rotate
      final spiralAngle = star.angle + (starProgress * 2 * math.pi);
      final spiralDistance = star.distance * (1.0 - starProgress * 0.3) * maxRadius * pullPercentage;
      
      final x = center.dx + spiralDistance * math.cos(spiralAngle);
      final y = center.dy + spiralDistance * math.sin(spiralAngle);
      
      // Star opacity based on distance from center
      final opacity = (0.3 + (star.distance * 0.7)) * pullPercentage;
      
      final paint = Paint()
        ..color = star.color.withOpacity(opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      
      // Draw star with glow
      canvas.drawCircle(
        Offset(x, y), 
        star.size * pullPercentage, 
        paint,
      );
      
      // Subtle glow
      final glowPaint = Paint()
        ..color = star.color.withOpacity(opacity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(
        Offset(x, y), 
        star.size * 2 * pullPercentage, 
        glowPaint,
      );
    }
  }

  void _drawSpiralArms(Canvas canvas, Offset center, double maxRadius) {
    final armPaint = Paint()
      ..color = coreColor.withOpacity(0.1 * pullPercentage)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int arm = 0; arm < 2; arm++) {
      final path = Path();
      final startAngle = arm * math.pi + (progress * 2 * math.pi);
      
      for (double t = 0; t < 2 * math.pi; t += 0.1) {
        final radius = (t / (2 * math.pi)) * maxRadius * 0.8;
        final angle = startAngle + t;
        final x = center.dx + radius * math.cos(angle);
        final y = center.dy + radius * math.sin(angle);
        
        if (t == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      
      canvas.drawPath(path, armPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GalaxyPainter oldDelegate) => 
      oldDelegate.progress != progress || oldDelegate.pullPercentage != pullPercentage;
}
