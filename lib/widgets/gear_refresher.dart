import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Gear Rotation Pull-to-Refresh Animation
/// Interlocking gears spin together during refresh - technical/mechanical aesthetic
class GearRefresher extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final List<Widget> slivers;

  const GearRefresher({
    super.key,
    required this.onRefresh,
    required this.slivers,
  });

  @override
  State<GearRefresher> createState() => _GearRefresherState();
}

class _GearRefresherState extends State<GearRefresher> 
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _startRotation() {
    if (!_isRefreshing) {
      _isRefreshing = true;
      _rotationController.repeat();
    }
  }

  void _stopRotation() {
    _isRefreshing = false;
    _rotationController.stop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            _startRotation();
            await widget.onRefresh();
            _stopRotation();
            HapticFeedback.lightImpact();
          },
          builder: (context, refreshState, pulledExtent, refreshTriggerPullDistance, refreshIndicatorExtent) {
            final double percentage = (pulledExtent / refreshTriggerPullDistance).clamp(0.0, 1.0);
            
            if (refreshState == RefreshIndicatorMode.refresh && !_isRefreshing) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _startRotation());
            }
            
            return _buildGearHeader(
              context, 
              pulledExtent, 
              refreshState, 
              percentage,
              isDark,
            );
          },
        ),
        ...widget.slivers,
      ],
    );
  }

  Widget _buildGearHeader(
    BuildContext context,
    double pulledExtent,
    RefreshIndicatorMode refreshState,
    double percentage,
    bool isDark,
  ) {
    if (pulledExtent <= 1) return const SizedBox.shrink();

    // Colors
    final Color primaryGear = isDark ? const Color(0xFF00D9FF) : const Color(0xFF1E88E5);
    final Color secondaryGear = isDark ? const Color(0xFFFF6B9D) : const Color(0xFFE91E63);
    final Color tertiaryGear = isDark ? const Color(0xFF9C27B0) : const Color(0xFF7B1FA2);
    final Color textColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      height: pulledExtent,
      width: double.infinity,
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Gears
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              final double baseRotation = refreshState == RefreshIndicatorMode.refresh
                  ? _rotationController.value * 2 * math.pi
                  : percentage * math.pi * 0.5;

              return Stack(
                alignment: Alignment.center,
                children: [
                  // Large left gear (rotates clockwise)
                  Positioned(
                    left: MediaQuery.of(context).size.width / 2 - 55,
                    child: Opacity(
                      opacity: percentage.clamp(0.3, 1.0),
                      child: Transform.rotate(
                        angle: baseRotation,
                        child: CustomPaint(
                          size: const Size(50, 50),
                          painter: _GearPainter(
                            color: primaryGear,
                            teethCount: 12,
                            isDark: isDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Medium right gear (rotates counter-clockwise)
                  Positioned(
                    left: MediaQuery.of(context).size.width / 2 + 5,
                    child: Opacity(
                      opacity: percentage.clamp(0.3, 1.0),
                      child: Transform.rotate(
                        angle: -baseRotation * 1.2, // Opposite direction, slightly faster
                        child: CustomPaint(
                          size: const Size(40, 40),
                          painter: _GearPainter(
                            color: secondaryGear,
                            teethCount: 10,
                            isDark: isDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Small top gear (rotates clockwise faster)
                  Positioned(
                    top: pulledExtent / 2 - 35,
                    child: Opacity(
                      opacity: (percentage * 0.8).clamp(0.2, 0.8),
                      child: Transform.rotate(
                        angle: baseRotation * 1.5,
                        child: CustomPaint(
                          size: const Size(25, 25),
                          painter: _GearPainter(
                            color: tertiaryGear,
                            teethCount: 8,
                            isDark: isDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          // Status Text
          Positioned(
            bottom: 8,
            child: Opacity(
              opacity: percentage,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.black : Colors.white).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  refreshState == RefreshIndicatorMode.armed 
                      ? "Release" 
                      : refreshState == RefreshIndicatorMode.refresh 
                          ? "Syncing..." 
                          : "Pull",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for a gear/cog shape
class _GearPainter extends CustomPainter {
  final Color color;
  final int teethCount;
  final bool isDark;

  _GearPainter({
    required this.color,
    required this.teethCount,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.65;
    final toothDepth = outerRadius * 0.2;
    final holeRadius = innerRadius * 0.35;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // Draw shadow
    canvas.save();
    canvas.translate(2, 2);
    _drawGear(canvas, center, outerRadius, innerRadius, toothDepth, shadowPaint);
    canvas.restore();

    // Draw main gear
    _drawGear(canvas, center, outerRadius, innerRadius, toothDepth, paint);

    // Draw center hole
    final holePaint = Paint()
      ..color = isDark ? const Color(0xFF1A1A2E) : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, holeRadius, holePaint);

    // Draw center axle dot
    final axlePaint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, holeRadius * 0.4, axlePaint);

    // Draw gear outline
    final outlinePaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, innerRadius, outlinePaint);
  }

  void _drawGear(Canvas canvas, Offset center, double outerRadius, 
      double innerRadius, double toothDepth, Paint paint) {
    final path = Path();
    final toothAngle = 2 * math.pi / teethCount;
    final halfTooth = toothAngle / 4;

    for (int i = 0; i < teethCount; i++) {
      final angle = i * toothAngle;
      
      // Inner point before tooth
      final innerX1 = center.dx + innerRadius * math.cos(angle - halfTooth);
      final innerY1 = center.dy + innerRadius * math.sin(angle - halfTooth);
      
      // Outer point (tooth peak left)
      final outerX1 = center.dx + outerRadius * math.cos(angle - halfTooth * 0.5);
      final outerY1 = center.dy + outerRadius * math.sin(angle - halfTooth * 0.5);
      
      // Outer point (tooth peak right)
      final outerX2 = center.dx + outerRadius * math.cos(angle + halfTooth * 0.5);
      final outerY2 = center.dy + outerRadius * math.sin(angle + halfTooth * 0.5);
      
      // Inner point after tooth
      final innerX2 = center.dx + innerRadius * math.cos(angle + halfTooth);
      final innerY2 = center.dy + innerRadius * math.sin(angle + halfTooth);

      if (i == 0) {
        path.moveTo(innerX1, innerY1);
      } else {
        path.lineTo(innerX1, innerY1);
      }
      
      path.lineTo(outerX1, outerY1);
      path.lineTo(outerX2, outerY2);
      path.lineTo(innerX2, innerY2);
    }
    
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GearPainter oldDelegate) => 
      oldDelegate.color != color || oldDelegate.teethCount != teethCount;
}
