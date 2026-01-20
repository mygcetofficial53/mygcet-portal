import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Liquid Blob Pull-to-Refresh Animation
/// A morphing liquid blob that stretches and bounces - premium iOS-like aesthetic
class LiquidBlobRefresher extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final List<Widget> slivers;

  const LiquidBlobRefresher({
    super.key,
    required this.onRefresh,
    required this.slivers,
  });

  @override
  State<LiquidBlobRefresher> createState() => _LiquidBlobRefresherState();
}

class _LiquidBlobRefresherState extends State<LiquidBlobRefresher> 
    with TickerProviderStateMixin {
  late AnimationController _morphController;
  late AnimationController _pulseController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _morphController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _morphController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startAnimation() {
    if (!_isRefreshing) {
      _isRefreshing = true;
      _morphController.repeat();
      _pulseController.repeat(reverse: true);
    }
  }

  void _stopAnimation() {
    _isRefreshing = false;
    _morphController.stop();
    _pulseController.stop();
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
            
            return _buildBlobHeader(
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

  Widget _buildBlobHeader(
    BuildContext context,
    double pulledExtent,
    RefreshIndicatorMode refreshState,
    double percentage,
  ) {
    if (pulledExtent <= 1) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Gradient colors for the blob
    final List<Color> blobColors = isDark 
        ? [const Color(0xFF667eea), const Color(0xFF764ba2), const Color(0xFFf093fb)]
        : [const Color(0xFF4facfe), const Color(0xFF00f2fe), const Color(0xFF43e97b)];
    
    final Color textColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      height: pulledExtent,
      width: double.infinity,
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Liquid Blob
          AnimatedBuilder(
            animation: Listenable.merge([_morphController, _pulseController]),
            builder: (context, child) {
              final double morphValue = refreshState == RefreshIndicatorMode.refresh
                  ? _morphController.value
                  : percentage * 0.3;
              
              final double pulseValue = refreshState == RefreshIndicatorMode.refresh
                  ? 1.0 + (_pulseController.value * 0.15)
                  : 0.5 + (percentage * 0.5);

              final double baseSize = 50 + (percentage * 30);

              return CustomPaint(
                size: Size(baseSize * 2, baseSize * 2),
                painter: _LiquidBlobPainter(
                  morphProgress: morphValue,
                  scale: pulseValue,
                  colors: blobColors,
                  isDark: isDark,
                ),
              );
            },
          ),
          
          // Inner glow effect
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final double glowOpacity = refreshState == RefreshIndicatorMode.refresh
                  ? 0.3 + (_pulseController.value * 0.2)
                  : percentage * 0.3;
              
              return Container(
                width: 30 + (percentage * 20),
                height: 30 + (percentage * 20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: blobColors[1].withOpacity(glowOpacity),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Status icon in center
          Opacity(
            opacity: percentage,
            child: Icon(
              refreshState == RefreshIndicatorMode.refresh 
                  ? Icons.sync 
                  : refreshState == RefreshIndicatorMode.armed
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
              color: Colors.white.withOpacity(0.9),
              size: 20 + (percentage * 8),
            ),
          ),
          
          // Status Text
          Positioned(
            bottom: 8,
            child: Opacity(
              opacity: percentage * 0.8,
              child: Text(
                refreshState == RefreshIndicatorMode.armed 
                    ? "Release to sync" 
                    : refreshState == RefreshIndicatorMode.refresh 
                        ? "Syncing..." 
                        : "Pull to refresh",
                style: TextStyle(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for a morphing liquid blob
class _LiquidBlobPainter extends CustomPainter {
  final double morphProgress;
  final double scale;
  final List<Color> colors;
  final bool isDark;

  _LiquidBlobPainter({
    required this.morphProgress,
    required this.scale,
    required this.colors,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = (size.width / 4) * scale;

    // Create gradient paint
    final paint = Paint()
      ..shader = RadialGradient(
        colors: colors,
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius * 1.5))
      ..style = PaintingStyle.fill;

    // Draw shadow
    final shadowPaint = Paint()
      ..color = colors[1].withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    
    canvas.drawPath(_createBlobPath(center, baseRadius * 0.9, morphProgress), shadowPaint);

    // Draw main blob
    canvas.drawPath(_createBlobPath(center, baseRadius, morphProgress), paint);

    // Draw highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(center.dx - baseRadius * 0.3, center.dy - baseRadius * 0.3),
      baseRadius * 0.2,
      highlightPaint,
    );
  }

  Path _createBlobPath(Offset center, double radius, double progress) {
    final path = Path();
    const int points = 8;
    final List<Offset> blobPoints = [];

    for (int i = 0; i < points; i++) {
      final angle = (i / points) * 2 * math.pi;
      
      // Create organic morphing effect
      final wobble1 = math.sin(progress * 2 * math.pi + angle * 2) * 0.15;
      final wobble2 = math.cos(progress * 2 * math.pi + angle * 3) * 0.1;
      final wobble3 = math.sin(progress * 4 * math.pi + angle) * 0.08;
      
      final dynamicRadius = radius * (1.0 + wobble1 + wobble2 + wobble3);
      
      final x = center.dx + dynamicRadius * math.cos(angle);
      final y = center.dy + dynamicRadius * math.sin(angle);
      blobPoints.add(Offset(x, y));
    }

    // Create smooth curve through points using cubic bezier
    path.moveTo(blobPoints[0].dx, blobPoints[0].dy);
    
    for (int i = 0; i < points; i++) {
      final p0 = blobPoints[i];
      final p1 = blobPoints[(i + 1) % points];
      final p2 = blobPoints[(i + 2) % points];
      
      final cp1x = p0.dx + (p1.dx - blobPoints[(i - 1 + points) % points].dx) / 4;
      final cp1y = p0.dy + (p1.dy - blobPoints[(i - 1 + points) % points].dy) / 4;
      final cp2x = p1.dx - (p2.dx - p0.dx) / 4;
      final cp2y = p1.dy - (p2.dy - p0.dy) / 4;
      
      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p1.dx, p1.dy);
    }

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _LiquidBlobPainter oldDelegate) => 
      oldDelegate.morphProgress != morphProgress || 
      oldDelegate.scale != scale;
}
