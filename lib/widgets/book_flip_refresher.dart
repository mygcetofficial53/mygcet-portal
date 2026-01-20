import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BookFlipRefresher extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final List<Widget> slivers;

  const BookFlipRefresher({
    super.key,
    required this.onRefresh,
    required this.slivers,
  });

  @override
  State<BookFlipRefresher> createState() => _BookFlipRefresherState();
}

class _BookFlipRefresherState extends State<BookFlipRefresher> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            await widget.onRefresh();
            HapticFeedback.lightImpact();
          },
          builder: (context, refreshState, pulledExtent, refreshTriggerPullDistance, refreshIndicatorExtent) {
            final double percentage = (pulledExtent / refreshTriggerPullDistance).clamp(0.0, 1.0);
            
            return _buildBlueprintHeader(
              context, 
              pulledExtent, 
              refreshTriggerPullDistance, 
              refreshState, 
              percentage,
              isDark
            );
          },
        ),
        ...widget.slivers,
      ],
    );
  }

  Widget _buildBlueprintHeader(
    BuildContext context,
    double pulledExtent,
    double triggerDistance,
    RefreshIndicatorMode refreshState,
    double percentage,
    bool isDark,
  ) {
    // Colors - TRANSPARENT BACKGROUND to show the main app gradient
    final Color bluePrintBg = Colors.transparent; 
    // Adjust grid for contrast against the purple/dark gradient
    // White/Cyan grid looks good on both dark and light gradients
    final Color gridColor = isDark ? Colors.cyan.withOpacity(0.15) : Colors.white.withOpacity(0.2);
    final Color textColor = isDark ? Colors.cyanAccent : Colors.white;
    final Color accentColor = isDark ? Colors.purpleAccent : Colors.amberAccent;

    // Only show if pulled
    if (pulledExtent <= 1) return const SizedBox.shrink();

    return Container(
      height: pulledExtent,
      width: double.infinity,
      color: bluePrintBg,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Grid Background
          Positioned.fill(
            child: CustomPaint(
              painter: _BlueprintGridPainter(
                color: gridColor,
                offset: 0, // Could animate this for parallax
                scale: 1.0 + (percentage * 0.1),
              ),
            ),
          ),

          // Content
          Center(
            child: OverflowBox(
              minHeight: 0,
              maxHeight: double.infinity,
              alignment: Alignment.center,
              child: Opacity(
                opacity: percentage,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Icon/Schematic
                    SizedBox(
                      height: 40,
                      width: 40,
                      child: CustomPaint(
                        painter: _SchematicSpinnerPainter(
                          color: textColor,
                          accent: accentColor,
                          rotation: refreshState == RefreshIndicatorMode.refresh 
                              ? (DateTime.now().millisecondsSinceEpoch / 1000) * 2 * math.pi 
                              : percentage * math.pi,
                          isRefreshing: refreshState == RefreshIndicatorMode.refresh,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Text
                    Text(
                      refreshState == RefreshIndicatorMode.armed 
                          ? "RELEASE" 
                          : refreshState == RefreshIndicatorMode.refresh 
                              ? "UPDATING..." 
                              : "PULL DOWN",
                      style: TextStyle(
                        color: textColor.withOpacity(0.9),
                        fontSize: 9, 
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontFamily: 'Courier', 
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // "Page Edge" Shadow at the bottom
          Positioned(
            bottom: -5,
            left: 0,
            right: 0,
            height: 20,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3 * percentage),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlueprintGridPainter extends CustomPainter {
  final Color color;
  final double offset;
  final double scale;

  _BlueprintGridPainter({required this.color, required this.offset, this.scale = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final double gridSize = 30.0 * scale;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    // Crosshairs
    final thickPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 2.0;
      
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.2), 
      Offset(size.width * 0.1 + 10, size.height * 0.2), 
      thickPaint
    );
     canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.2 - 5), 
      Offset(size.width * 0.1, size.height * 0.2 + 5), 
      thickPaint
    );
  }

  @override
  bool shouldRepaint(covariant _BlueprintGridPainter oldDelegate) => 
      oldDelegate.scale != scale || oldDelegate.color != color;
}

class _SchematicSpinnerPainter extends CustomPainter {
  final Color color;
  final Color accent;
  final double rotation;
  final bool isRefreshing;

  _SchematicSpinnerPainter({
    required this.color, 
    required this.accent, 
    required this.rotation,
    required this.isRefreshing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
      
    // Outer dashed circle
    const dashWidth = 4;
    const dashSpace = 4;
    double startAngle = 0;
    while (startAngle < 2 * math.pi) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius),
        startAngle,
        dashWidth / radius,
        false,
        paint,
      );
      startAngle += (dashWidth + dashSpace) / radius;
    }
    
    // Inner Triangle/Arrow
    final path = Path();
    path.moveTo(0, -radius * 0.6);
    path.lineTo(radius * 0.5, radius * 0.4);
    path.lineTo(-radius * 0.5, radius * 0.4);
    path.close();
    
    paint.style = PaintingStyle.fill;
    paint.color = accent.withOpacity(0.8);
    canvas.drawPath(path, paint);
    
    // Center Dot
    paint.color = color;
    canvas.drawCircle(Offset.zero, 3, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SchematicSpinnerPainter oldDelegate) => 
      oldDelegate.rotation != rotation;
}
