import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Paper Airplane Pull-to-Refresh Animation
/// An origami-style paper airplane flies across the screen during refresh
class PaperAirplaneRefresher extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final List<Widget> slivers;

  const PaperAirplaneRefresher({
    super.key,
    required this.onRefresh,
    required this.slivers,
  });

  @override
  State<PaperAirplaneRefresher> createState() => _PaperAirplaneRefresherState();
}

class _PaperAirplaneRefresherState extends State<PaperAirplaneRefresher> 
    with SingleTickerProviderStateMixin {
  late AnimationController _flyController;
  late Animation<double> _flyAnimation;
  late Animation<double> _wobbleAnimation;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _flyController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _flyAnimation = Tween<double>(begin: -0.2, end: 1.2).animate(
      CurvedAnimation(parent: _flyController, curve: Curves.easeInOutCubic),
    );
    
    _wobbleAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _flyController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _flyController.dispose();
    super.dispose();
  }

  void _startFlyAnimation() {
    if (!_isRefreshing) {
      _isRefreshing = true;
      _flyController.repeat();
    }
  }

  void _stopFlyAnimation() {
    _isRefreshing = false;
    _flyController.stop();
    _flyController.reset();
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
            _startFlyAnimation();
            await widget.onRefresh();
            _stopFlyAnimation();
            HapticFeedback.lightImpact();
          },
          builder: (context, refreshState, pulledExtent, refreshTriggerPullDistance, refreshIndicatorExtent) {
            final double percentage = (pulledExtent / refreshTriggerPullDistance).clamp(0.0, 1.0);
            
            // Start fly animation when refreshing
            if (refreshState == RefreshIndicatorMode.refresh && !_isRefreshing) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _startFlyAnimation());
            }
            
            return _buildAirplaneHeader(
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

  Widget _buildAirplaneHeader(
    BuildContext context,
    double pulledExtent,
    RefreshIndicatorMode refreshState,
    double percentage,
    bool isDark,
  ) {
    if (pulledExtent <= 1) return const SizedBox.shrink();

    final Color planeColor = isDark ? Colors.cyanAccent : Colors.blue.shade700;
    final Color trailColor = isDark ? Colors.purple.withOpacity(0.3) : Colors.blue.withOpacity(0.2);
    final Color textColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      height: pulledExtent,
      width: double.infinity,
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Trail effect (dashed line path)
          if (refreshState == RefreshIndicatorMode.refresh)
            AnimatedBuilder(
              animation: _flyAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(MediaQuery.of(context).size.width, pulledExtent),
                  painter: _TrailPainter(
                    progress: _flyAnimation.value,
                    color: trailColor,
                    isDark: isDark,
                  ),
                );
              },
            ),
          
          // Paper Airplane
          AnimatedBuilder(
            animation: _flyController,
            builder: (context, child) {
              final double xPos = refreshState == RefreshIndicatorMode.refresh
                  ? _flyAnimation.value * MediaQuery.of(context).size.width
                  : percentage * MediaQuery.of(context).size.width * 0.3 + 20;
              
              final double yPos = pulledExtent / 2 + 
                  (refreshState == RefreshIndicatorMode.refresh 
                      ? math.sin(_flyController.value * math.pi * 4) * 8 
                      : 0);
              
              final double rotation = refreshState == RefreshIndicatorMode.refresh
                  ? _wobbleAnimation.value + math.sin(_flyController.value * math.pi * 2) * 0.15
                  : percentage * 0.2 - 0.1;

              return Positioned(
                left: xPos - 20,
                top: yPos - 15,
                child: Opacity(
                  opacity: percentage.clamp(0.3, 1.0),
                  child: Transform.rotate(
                    angle: rotation,
                    child: CustomPaint(
                      size: const Size(40, 30),
                      painter: _PaperAirplanePainter(
                        color: planeColor,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Status Text
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 50),
              child: Opacity(
                opacity: percentage,
                child: Text(
                  refreshState == RefreshIndicatorMode.armed 
                      ? "Release to refresh" 
                      : refreshState == RefreshIndicatorMode.refresh 
                          ? "Flying..." 
                          : "Pull down",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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

/// Custom painter for the paper airplane
class _PaperAirplanePainter extends CustomPainter {
  final Color color;
  final bool isDark;

  _PaperAirplanePainter({required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Paper airplane shape
    final path = Path();
    // Nose
    path.moveTo(size.width, size.height * 0.5);
    // Top wing
    path.lineTo(0, 0);
    // Body center
    path.lineTo(size.width * 0.3, size.height * 0.5);
    // Bottom wing
    path.lineTo(0, size.height);
    // Back to nose
    path.close();

    // Draw shadow first
    canvas.save();
    canvas.translate(2, 2);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // Draw plane
    canvas.drawPath(path, paint);

    // Add fold line
    final foldPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.2)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width, size.height * 0.5),
      Offset(size.width * 0.3, size.height * 0.5),
      foldPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PaperAirplanePainter oldDelegate) => 
      oldDelegate.color != color;
}

/// Custom painter for the trail effect
class _TrailPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isDark;

  _TrailPainter({required this.progress, required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw dashed trail
    final double endX = progress * size.width;
    final double startX = math.max(0, endX - size.width * 0.4);
    final double centerY = size.height / 2;

    const double dashWidth = 8;
    const double dashSpace = 6;

    double currentX = startX;
    while (currentX < endX) {
      final double dashEnd = math.min(currentX + dashWidth, endX);
      // Sinusoidal wave for trail
      final double y1 = centerY + math.sin(currentX / 20) * 5;
      final double y2 = centerY + math.sin(dashEnd / 20) * 5;
      
      // Fade trail based on distance from plane
      final double opacity = ((currentX - startX) / (endX - startX)).clamp(0.0, 1.0);
      paint.color = color.withOpacity(opacity * 0.5);
      
      canvas.drawLine(Offset(currentX, y1), Offset(dashEnd, y2), paint);
      currentX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _TrailPainter oldDelegate) => 
      oldDelegate.progress != progress;
}
