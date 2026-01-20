import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/glass_container.dart';

class IdCardScreen extends StatelessWidget {
  const IdCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authService = context.watch<AuthService>();
    final student = authService.currentUser;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Student ID Card'),
        backgroundColor: isDark ? const Color(0xFF161B22) : AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _IdCard(
            studentName: student?.name ?? 'Student Name',
            enrollmentNumber: student?.enrollment ?? student?.rollNumber ?? 'XXXXXXXXXX',
            branch: student?.branch ?? 'Department',
            semester: student?.semester ?? 'Semester',
            section: student?.section ?? 'Section',
            batch: student?.batch ?? 'Batch',
            photoUrl: student?.photoUrl,
            isDark: isDark,
          ),
        ),
      ),
    );
  }
}

class _IdCard extends StatelessWidget {
  final String studentName;
  final String enrollmentNumber;
  final String branch;
  final String semester;
  final String section;
  final String batch;
  final String? photoUrl;
  final bool isDark;

  const _IdCard({
    required this.studentName,
    required this.enrollmentNumber,
    required this.branch,
    required this.semester,
    required this.section,
    required this.batch,
    this.photoUrl,
    required this.isDark,
  });

  String _getInitials(String name) {
    if (name.isEmpty) return 'ST';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1a1a2e), const Color(0xFF16213e)]
              : [const Color(0xFF1565C0), const Color(0xFF0D47A1)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D47A1).withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Holographic/Noise overlay effect (simulated)
          Positioned.fill(
             child: ClipRRect(
               borderRadius: BorderRadius.circular(24),
               child: Container(
                 decoration: BoxDecoration(
                   gradient: LinearGradient(
                     begin: Alignment.topLeft,
                     end: Alignment.bottomRight,
                     colors: [
                       Colors.white.withValues(alpha: 0.05),
                       Colors.transparent,
                       Colors.white.withValues(alpha: 0.02),
                     ],
                     stops: const [0.0, 0.5, 1.0],
                   ),
                 ),
               ),
             ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                           BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8)
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/My GCET_20251225_134706_0000.png', 
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                             Container(color: Colors.white, child: const Icon(Icons.school, color: Colors.blue)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'GCET',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'G H Patel College of\nEngineering & Technology',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 11,
                              height: 1.2,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Avatar & Name
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 3),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.2),
                              Colors.white.withValues(alpha: 0.05),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(studentName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        studentName.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Text(
                          enrollmentNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Info Grid - Glass Cards
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                       _buildPremiumInfoRow('Branch', branch.isNotEmpty ? branch : 'Engineering'),
                       const Divider(color: Colors.white24, height: 24),
                       Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Expanded(child: _buildPremiumInfoColumn('Sem', semester.isNotEmpty ? semester : 'N/A')),
                           Container(width: 1, height: 30, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 8)),
                           Expanded(child: _buildPremiumInfoColumn('Sec', section.isNotEmpty ? section : 'N/A')),
                           if (batch.isNotEmpty && batch != 'N/A') ...[
                             Container(width: 1, height: 30, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 8)),
                             Expanded(child: _buildPremiumInfoColumn('Batch', batch)),
                           ],
                         ],
                       ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                
                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified, color: Colors.blue.shade100, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Valid for Academic Year 2025-2026',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Decorative corner accents
          Positioned(top: 15, right: 15, child: Icon(Icons.nfc, color: Colors.white.withValues(alpha: 0.15), size: 40)),
        ],
      ),
    );
  }

  Widget _buildPremiumInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w600),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumInfoColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
