import 'dart:math' as math;
import 'package:flutter/material.dart';

class WeatherVisuals extends StatelessWidget {
  final int iconNum;
  final bool isDay;

  const WeatherVisuals({
    super.key,
    required this.iconNum,
    required this.isDay,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildWeatherScene(),
        ],
      ),
    );
  }
  
  static Color getGlowColor(int iconNum, bool isDay) {
    // FOG
    if (iconNum == 9) return Colors.grey;
    
    // THUNDERSTORM
    if (iconNum == 14 || iconNum == 15) return const Color(0xFF263238);

    // RAIN
    if ((iconNum >= 10 && iconNum <= 13) || iconNum == 32 || (iconNum >= 20 && iconNum <= 25)) {
       return isDay ? Colors.blueGrey.shade400 : const Color(0xFF1A237E);
    }

    // CLOUDY / OVERCAST
    if ((iconNum >= 6 && iconNum <= 8) || iconNum == 30 || iconNum == 31) {
       return isDay ? Colors.grey.shade400 : Colors.blueGrey.shade700;
    }
    
    // SUNNY / CLEAR
    if (isDay) {
      return Colors.orangeAccent;
    } else {
      return const Color(0xFF311B92); // Deep Purple for clear night
    }
  }

  Widget _buildWeatherScene() {
    // FOG (9)
    if (iconNum == 9) return const FoggyScene();

    // THUNDERSTORM (14, 15)
    if (iconNum == 14 || iconNum == 15) return const StormScene();

    // RAIN (10-13, 20-25, 32)
    if ((iconNum >= 10 && iconNum <= 13) || iconNum == 32 || (iconNum >= 20 && iconNum <= 25)) {
      return RainScene(isDay: isDay);
    }

    // CLOUDY (6-8, 30-31)
    if ((iconNum >= 6 && iconNum <= 8) || iconNum == 30 || iconNum == 31) {
      return CloudyScene(isDay: isDay, density: CloudDensity.high);
    }

    // PARTLY CLOUDY (4-5, 28-29)
    if ((iconNum >= 4 && iconNum <= 5) || iconNum == 28 || iconNum == 29) {
      return CloudyScene(isDay: isDay, density: CloudDensity.medium);
    }

    // SUNNY / CLEAR (2-3, 26-27)
    return SunnyScene(isDay: isDay);
  }
}

// -----------------------------------------------------------------------------
// 1. DYNAMIC SUNNY / CLEAR SCENE
// -----------------------------------------------------------------------------
class SunnyScene extends StatefulWidget {
  final bool isDay;
  const SunnyScene({super.key, required this.isDay});

  @override
  State<SunnyScene> createState() => _SunnySceneState();
}

class _SunnySceneState extends State<SunnyScene> with TickerProviderStateMixin {
  late AnimationController _rotateController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isDay) {
      return const MoonWidget();
    }
    
    return Stack(
      children: [
        // Floating Background Particles (Dust/Pollen)
        const FloatingParticles(count: 8, color: Colors.white24),

        // Rotating Rays
        Positioned(
          top: -100,
          right: -100,
          child: RotationTransition(
            turns: _rotateController,
            child: SizedBox(
              width: 500, 
              height: 500,
              child: CustomPaint(
                painter: SunRaysPainter(),
              ),
            ),
          ),
        ),
        
        // Pulsing Sun Core
        Positioned(
          top: 40,
          right: 40,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
               return Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFFEA00), Color(0xFFFF9800)],
                    center: Alignment(-0.3, -0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orangeAccent.withOpacity(0.4 + (_pulseController.value * 0.2)),
                      blurRadius: 40 + (_pulseController.value * 20),
                      spreadRadius: 10 + (_pulseController.value * 10),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class MoonWidget extends StatefulWidget {
  const MoonWidget({super.key});

  @override
  State<MoonWidget> createState() => _MoonWidgetState();
}

class _MoonWidgetState extends State<MoonWidget> with SingleTickerProviderStateMixin {
   late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const FloatingParticles(count: 15, color: Colors.white30), // Stars
        Positioned(
          right: 30,
          top: 30,
          child: AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFF5F5F5), Color(0xFFBDBDBD)],
                     center: Alignment(-0.4, -0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1 + (_glowController.value * 0.15)),
                      blurRadius: 25 + (_glowController.value * 15),
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: Stack(
              children: [
                _buildCrater(25, 30, 18),
                _buildCrater(60, 50, 12),
                _buildCrater(50, 20, 10),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCrater(double top, double left, double size) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}


// -----------------------------------------------------------------------------
// 2. PARALLAX CLOUDY SCENE
// -----------------------------------------------------------------------------
enum CloudDensity { medium, high }

class CloudyScene extends StatefulWidget {
  final bool isDay;
  final CloudDensity density;
  
  const CloudyScene({super.key, required this.isDay, required this.density});

  @override
  State<CloudyScene> createState() => _CloudySceneState();
}

class _CloudySceneState extends State<CloudyScene> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 60s Duration: ~40s of clouds passing, ~20s of empty sky (gap)
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 60))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth > 0 ? constraints.maxWidth : 350.0;
        
        // Train Logic:
        // We define a "Virtual Path" that is longer than the screen.
        // Clouds are positioned relative to the "Head" of the train.
        // Head moves from [Start] to [End].
        // Gap is created because the Track is much longer than the Screen + Train Length.
        
        // FG Train
        final fgTrackLen = w + 1600; // Long track for fast movement
        final fgStart = -400.0;     // Start off-screen left
        
        // BG Train (Slower -> Shorter track in same time)
        final bgTrackLen = w + 1200; 
        final bgStart = -300.0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // 0. Sun/Moon (Fixed)
            if (widget.density == CloudDensity.medium)
             widget.isDay ? 
               const Positioned(top: 20, right: 30, child: SunOrb(size: 80)) : 
               const MoonWidget(),

            // --- BACKGROUND LAYER (Slower) ---
            
            // BG Cloud 1
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // Pos = Start + (Progress * Track) - Offset
                final dx = bgStart + (_controller.value * bgTrackLen);
                return Positioned(
                  top: 40,
                  left: dx, 
                  child: Opacity(
                    opacity: 0.6,
                    child: Transform.scale(
                      scale: 0.8,
                      child: const OrganicCloudWidget(width: 250, color: Colors.white70),
                    ),
                  ),
                );
              },
            ),
            
            // BG Cloud 2 (Trailing behind BG 1)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // Offset by 300px
                final dx = (bgStart - 300) + (_controller.value * bgTrackLen);
                return Positioned(
                  top: 10,
                  left: dx,
                  child: Opacity(
                    opacity: 0.5,
                    child: Transform.scale(
                      scale: 0.7,
                       child: const OrganicCloudWidget(width: 200, color: Colors.white60),
                    ),
                  ),
                );
              },
            ),

            // --- FOREGROUND LAYER (Faster) ---
            
            // FG Cloud 1 (Lead)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final dx = fgStart + (_controller.value * fgTrackLen);
                return Positioned(
                  top: 60,
                  left: dx,
                  child: const OrganicCloudWidget(width: 320, color: Colors.white),
                );
              },
            ),

            // FG Cloud 2 (Trailing 350px)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final dx = (fgStart - 350) + (_controller.value * fgTrackLen);
                return Positioned(
                  top: 90,
                  left: dx,
                  child: const OrganicCloudWidget(width: 280, color: Colors.white),
                );
              },
            ),
            
            // FG Cloud 3 (Trailing 700px)
            if (widget.density == CloudDensity.high || true) // Always show for "4-5 clouds" request
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final dx = (fgStart - 700) + (_controller.value * fgTrackLen);
                return Positioned(
                  top: 40,
                  left: dx,
                  child: const OrganicCloudWidget(width: 260, color: Colors.white),
                );
              },
            ),
          ],
        );
      }
    );
  }
}

class SunOrb extends StatelessWidget {
  final double size;
  const SunOrb({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Colors.orangeAccent, Colors.deepOrange],
        ),
         boxShadow: [
          BoxShadow(color: Colors.orange.withOpacity(0.5), blurRadius: 30, spreadRadius: 5),
        ],
      ),
    );
  }
}

class OrganicCloudWidget extends StatelessWidget {
  final double width;
  final Color color;
  
  const OrganicCloudWidget({super.key, required this.width, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 0.6,
      child: CustomPaint(
        painter: OrganicCloudPainter(color: color),
      ),
    );
  }
}

class OrganicCloudPainter extends CustomPainter {
  final Color color;
  OrganicCloudPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, color.withOpacity(0.8)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    
    // Add subtle shadow for 3D feel
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final path = Path();
    final w = size.width;
    final h = size.height;
    
    // Draw base circles efficiently
    // Overlapping circles to create fluff
    
    final circles = <Map<String, double>>[
      {'cx': w * 0.2, 'cy': h * 0.7, 'r': w * 0.2},
      {'cx': w * 0.35, 'cy': h * 0.55, 'r': w * 0.25}, // Top Left
      {'cx': w * 0.65, 'cy': h * 0.5, 'r': w * 0.3},  // Top Right (Big)
      {'cx': w * 0.8, 'cy': h * 0.7, 'r': w * 0.18},
      {'cx': w * 0.5, 'cy': h * 0.75, 'r': w * 0.25}, // Bottom fill
    ];
    
    // Draw Shadow First
    for(var c in circles) {
      canvas.drawCircle(Offset(c['cx']!, c['cy']! + 5), c['r']!, shadowPaint);
    }

    // Draw Main Cloud
    for(var c in circles) {
      canvas.drawCircle(Offset(c['cx']!, c['cy']!), c['r']!, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


// -----------------------------------------------------------------------------
// 3. RAIN SCENE
// -----------------------------------------------------------------------------
class RainScene extends StatefulWidget {
  final bool isDay;
  const RainScene({super.key, required this.isDay});

  @override
  State<RainScene> createState() => _RainSceneState();
}

class _RainSceneState extends State<RainScene> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
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
        // Darker Clouds
        const Positioned(
          top: 20, left: 20, 
          child: OrganicCloudWidget(width: 280, color: Color(0xFF90A4AE))
        ),
         const Positioned(
          top: 60, left: 150, 
          child: OrganicCloudWidget(width: 250, color: Color(0xFF78909C))
        ),
        
        // Rain Drops (Slanted)
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Positioned.fill(
              top: 50,
              child: CustomPaint(
                painter: RainPainter(animationValue: _controller.value),
              ),
            );
          },
        ),
      ],
    );
  }
}

class RainPainter extends CustomPainter {
  final double animationValue;

  RainPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.lightBlueAccent.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final random = math.Random(42); 

    for (int i = 0; i < 100; i++) {
        double startX = random.nextDouble() * size.width; 
        double startY = random.nextDouble() * size.height;
        
        // Animate Y position
        double dy = (startY + (animationValue * size.height * 2)) % size.height;
        // Slant X position (wind effect)
        double dx = (startX - (dy * 0.2)) % size.width;
        if(dx < 0) dx += size.width;

        canvas.drawLine(Offset(dx, dy), Offset(dx - 5, dy + 12), paint);
    }
  }

  @override
  bool shouldRepaint(covariant RainPainter oldDelegate) => true;
}


// -----------------------------------------------------------------------------
// 4. STORM SCENE
// -----------------------------------------------------------------------------
class StormScene extends StatefulWidget {
  const StormScene({super.key});

  @override
  State<StormScene> createState() => _StormSceneState();
}

class _StormSceneState extends State<StormScene> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
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
        // Storm Clouds
        const Positioned(
          top: 30, left: 40,
          child: OrganicCloudWidget(width: 300, color: Color(0xFF546E7A)),
        ),
        
        // Lightning
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Random flashes
            final val = _controller.value;
            final flash1 = val > 0.45 && val < 0.48;
            final flash2 = val > 0.88 && val < 0.90;
            
            if (!flash1 && !flash2) return const SizedBox();
            
            return Positioned(
              top: flash1 ? 80 : 60,
              left: flash1 ? 120 : 200,
              child: Icon(Icons.flash_on, 
                color: Colors.yellowAccent.withOpacity(0.8), 
                size: flash1 ? 60 : 80
              ),
            );
          },
        ),
        
        // Heavy Rain
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Positioned.fill(
              top: 50,
              child: CustomPaint(
                painter: RainPainter(animationValue: (_controller.value * 5) % 1.0), // Fast rain
              ),
            );
          },
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 5. FOG SCENE
// -----------------------------------------------------------------------------
class FoggyScene extends StatelessWidget {
  const FoggyScene({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
         const Positioned(
          top: 60, left: -50,
          child: OrganicCloudWidget(width: 350, color: Colors.white24),
        ),
        const Positioned(
          top: 40, right: -50,
          child: OrganicCloudWidget(width: 400, color: Colors.white24),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// HELPERS
// -----------------------------------------------------------------------------
class SunRaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.orangeAccent.withOpacity(0.15)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 18; i++) { // More rays
        final angle = (i * 20) * (math.pi / 180);
        final p1 = Offset(
           center.dx + math.cos(angle) * 60,
           center.dy + math.sin(angle) * 60,
        );
        final p2 = Offset(
           center.dx + math.cos(angle) * 160,
           center.dy + math.sin(angle) * 160,
        );
        canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FloatingParticles extends StatefulWidget {
  final int count;
  final Color color;
  const FloatingParticles({super.key, required this.count, required this.color});

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Offset> _offsets = [];
  final List<double> _speeds = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    final rng = math.Random();
    for(int i=0; i<widget.count; i++) {
      _offsets.add(Offset(rng.nextDouble() * 300, rng.nextDouble() * 150));
      _speeds.add(rng.nextDouble() + 0.5);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(
            offsets: _offsets,
            animationValue: _controller.value,
            speeds: _speeds,
            color: widget.color,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Offset> offsets;
  final double animationValue;
  final List<double> speeds;
  final Color color;

  ParticlePainter({required this.offsets, required this.animationValue, required this.speeds, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width > 0 ? size.width : 300.0;
    
    for(int i=0; i<offsets.length; i++) {
      double dx = (offsets[i].dx + (animationValue * 50 * speeds[i])) % w;
      double dy = offsets[i].dy + (math.sin(animationValue * 2 * math.pi + i) * 5); // Wavy motion
      
      canvas.drawCircle(Offset(dx, dy), 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}
