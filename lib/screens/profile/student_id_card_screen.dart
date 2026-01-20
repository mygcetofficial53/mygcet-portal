import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';

class StudentIdCardScreen extends StatefulWidget {
  const StudentIdCardScreen({super.key});

  @override
  State<StudentIdCardScreen> createState() => _StudentIdCardScreenState();
}

class _StudentIdCardScreenState extends State<StudentIdCardScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Rotation for geometric shapes
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Pulse animation for subtle movement
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    // Get initials
    String initials = 'ST';
    if (user?.name.isNotEmpty == true) {
      initials = user!.name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join().toUpperCase();
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Student ID Card'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: AspectRatio(
              aspectRatio: 0.75, // 3:4 aspect ratio, typical for ID cards
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 340), // Slightly narrower
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20), // Slightly smaller radius
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Base gradient
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                          ),
                        ),
                      ),
                      // Animated geometric background
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: Listenable.merge([_rotationController, _pulseAnimation]),
                          builder: (context, child) {
                            return CustomPaint(
                              painter: _GeometricPatternPainter(
                                rotation: _rotationController.value * 2 * math.pi,
                                scale: _pulseAnimation.value,
                              ),
                            );
                          },
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Header with Logo and College Name
                            Row(
                              children: [
                                // GCET Logo
                                Container(
                                  width: 48, // Reduced from 60
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/My GCET_20251225_134706_0000.png',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Center(
                                        child: Text('G', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // College Name
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'GCET',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20, // Reduced from 22
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      Text(
                                        'G H Patel College of\nEngineering & Technology',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.85),
                                          fontSize: 10, // Reduced from 12
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // QR Code placeholder icon
                                Container(
                                  padding: const EdgeInsets.all(6), // Reduced padding
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(Icons.qr_code_2, color: Colors.white.withOpacity(0.6), size: 24), // Reduced size
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16), // Reduced from 24
                            
                            // Avatar Circle with animated glow rings
                            SizedBox(
                              width: 110, // Reduced from 120
                              height: 110,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Animated glow rings
                                  AnimatedBuilder(
                                    animation: _pulseController,
                                    builder: (context, child) {
                                      return CustomPaint(
                                        size: const Size(110, 110),
                                        painter: _GlowRingsPainter(
                                          progress: _pulseController.value,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ),
                                  // Main avatar
                                  Container(
                                    width: 80, // Reduced from 86
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF4B6CB7),
                                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.15),
                                          blurRadius: 15,
                                          spreadRadius: 4,
                                        ),
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        initials,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 28, // Reduced from 32
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 12), // Reduced from 16
                            
                            // Student Name
                            Text(
                              user?.name ?? 'Student Name',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18, // Reduced from 20
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            const SizedBox(height: 6), // Reduced from 8
                            
                            // Enrollment Number Chip
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), // Reduced padding
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.25)),
                              ),
                              child: Text(
                                user?.enrollment ?? 'N/A',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13, // Reduced from 14
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 16), // Reduced from 20
                            
                            // Details Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12), // Reduced from 16
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: Column(
                                children: [
                                  // Branch
                                  _buildInfoRow('BRANCH', user?.branch ?? 'N/A'),
                                  const SizedBox(height: 8), // Reduced from 12
                                  // Semester and Section Row
                                  Row(
                                    children: [
                                      Expanded(child: _buildInfoColumn('SEM', user?.semester ?? 'N/A')),
                                      Container(width: 1, height: 24, color: Colors.white.withOpacity(0.2)), // height reduced from 32
                                      Expanded(child: _buildInfoColumn('SEC', user?.section ?? 'N/A')),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            const Spacer(), // Use Spacer to push validity to bottom if needed, or just tight spacing
                            
                            // Validity
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.verified, color: Colors.white.withOpacity(0.7), size: 16), // Reduced size
                                const SizedBox(width: 6),
                                Text(
                                  'Valid for Academic Year 2025-2026',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12, // Reduced from 13
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Custom painter for animated geometric patterns
class _GeometricPatternPainter extends CustomPainter {
  final double rotation;
  final double scale;

  _GeometricPatternPainter({required this.rotation, required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw multiple geometric shapes with different rotations and opacity
    _drawHexagons(canvas, size, paint, rotation, 0.08);
    _drawHexagons(canvas, size, paint, -rotation * 0.5, 0.05);
    _drawCircles(canvas, size, paint, rotation * 0.3, 0.06);
    _drawDiamonds(canvas, size, paint, rotation * 0.7, 0.04);
  }

  void _drawHexagons(Canvas canvas, Size size, Paint paint, double rot, double opacity) {
    paint.color = Colors.white.withOpacity(opacity);
    
    // Multiple hexagons at different positions
    final positions = [
      Offset(size.width * 0.2, size.height * 0.15),
      Offset(size.width * 0.85, size.height * 0.25),
      Offset(size.width * 0.1, size.height * 0.7),
      Offset(size.width * 0.9, size.height * 0.8),
    ];
    
    final sizes = [40.0, 50.0, 35.0, 45.0];
    
    for (int i = 0; i < positions.length; i++) {
      canvas.save();
      canvas.translate(positions[i].dx, positions[i].dy);
      canvas.rotate(rot + i * math.pi / 3);
      canvas.scale(scale);
      _drawHexagon(canvas, sizes[i], paint);
      canvas.restore();
    }
  }

  void _drawHexagon(Canvas canvas, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - math.pi / 2;
      final x = radius * math.cos(angle);
      final y = radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawCircles(Canvas canvas, Size size, Paint paint, double rot, double opacity) {
    paint.color = Colors.white.withOpacity(opacity);
    
    final positions = [
      Offset(size.width * 0.5, size.height * 0.1),
      Offset(size.width * 0.15, size.height * 0.45),
      Offset(size.width * 0.88, size.height * 0.55),
    ];
    
    for (int i = 0; i < positions.length; i++) {
      final radius = 20.0 + 15.0 * math.sin(rot + i * math.pi / 2);
      canvas.drawCircle(positions[i], radius * scale, paint);
    }
  }

  void _drawDiamonds(Canvas canvas, Size size, Paint paint, double rot, double opacity) {
    paint.color = Colors.white.withOpacity(opacity);
    
    final positions = [
      Offset(size.width * 0.7, size.height * 0.15),
      Offset(size.width * 0.3, size.height * 0.85),
    ];
    
    for (int i = 0; i < positions.length; i++) {
      canvas.save();
      canvas.translate(positions[i].dx, positions[i].dy);
      canvas.rotate(rot + i * math.pi / 4);
      canvas.scale(scale);
      _drawDiamond(canvas, 25.0, paint);
      canvas.restore();
    }
  }

  void _drawDiamond(Canvas canvas, double size, Paint paint) {
    final path = Path()
      ..moveTo(0, -size)
      ..lineTo(size * 0.6, 0)
      ..lineTo(0, size)
      ..lineTo(-size * 0.6, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GeometricPatternPainter oldDelegate) {
    return oldDelegate.rotation != rotation || oldDelegate.scale != scale;
  }
}

/// Painter for animated glow rings around the avatar
class _GlowRingsPainter extends CustomPainter {
  final double progress;
  final Color color;

  _GlowRingsPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw multiple expanding rings
    for (int i = 0; i < 3; i++) {
      final ringProgress = (progress + i * 0.33) % 1.0;
      final radius = 50 + (ringProgress * 20); // Expands from 50 to 70
      final opacity = (1 - ringProgress) * 0.3; // Fades out as it expands
      
      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 - (ringProgress * 0.5); // Gets thinner as it expands

      canvas.drawCircle(center, radius, paint);
    }
    
    // Draw subtle radial lines
    final linePaint = Paint()
      ..color = color.withOpacity(0.1 + progress * 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) + (progress * math.pi / 8);
      final innerRadius = 52.0;
      final outerRadius = 65.0 + math.sin(progress * math.pi * 2) * 5;
      
      final startPoint = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );
      final endPoint = Offset(
        center.dx + outerRadius * math.cos(angle),
        center.dy + outerRadius * math.sin(angle),
      );
      
      canvas.drawLine(startPoint, endPoint, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GlowRingsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
