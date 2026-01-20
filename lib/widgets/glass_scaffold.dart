import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A base scaffold with gradient background for consistent app-wide styling.
/// Provides iOS/macOS-style aesthetic with gradient backgrounds.
class GlassScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final List<Color>? gradientColors;
  final bool extendBodyBehindAppBar;
  final bool resizeToAvoidBottomInset;

  const GlassScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.gradientColors,
    this.extendBodyBehindAppBar = true,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultGradient = isDark
        ? const [
            Color(0xFF0D1117),
            Color(0xFF161B22),
            Color(0xFF21262D),
          ]
        : const [
            Color(0xFFF5F7FA),
            Color(0xFFE8EDF5),
            Color(0xFFDCE3ED),
          ];

    final colors = gradientColors ?? defaultGradient;

    // Set system UI overlay style based on theme
    SystemChrome.setSystemUIOverlayStyle(
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );

    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: appBar,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ),
        ),
        child: body,
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}

/// A variant with an animated gradient background
class AnimatedGlassScaffold extends StatefulWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final List<List<Color>>? gradientStops;
  final Duration animationDuration;

  const AnimatedGlassScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.gradientStops,
    this.animationDuration = const Duration(seconds: 3),
  });

  @override
  State<AnimatedGlassScaffold> createState() => _AnimatedGlassScaffoldState();
}

class _AnimatedGlassScaffoldState extends State<AnimatedGlassScaffold>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % _getGradientStops().length;
          });
          _controller.forward(from: 0);
        }
      });
    _controller.forward();
  }

  List<List<Color>> _getGradientStops() {
    return widget.gradientStops ??
        [
          [const Color(0xFF667eea), const Color(0xFF764ba2)],
          [const Color(0xFF11998e), const Color(0xFF38ef7d)],
          [const Color(0xFFfc4a1a), const Color(0xFFf7b733)],
        ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stops = _getGradientStops();
    final nextIndex = (_currentIndex + 1) % stops.length;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: widget.appBar,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    stops[_currentIndex][0],
                    stops[nextIndex][0],
                    _controller.value,
                  )!,
                  Color.lerp(
                    stops[_currentIndex][1],
                    stops[nextIndex][1],
                    _controller.value,
                  )!,
                ],
              ),
            ),
            child: widget.body,
          ),
          bottomNavigationBar: widget.bottomNavigationBar,
        );
      },
    );
  }
}
