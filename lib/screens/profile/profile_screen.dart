import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../services/theme_service.dart';
import '../../services/notification_service.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/animations/fade_in_slide.dart';
import '../../services/supabase_service.dart';
import '../admin/admin_create_event_screen.dart';
import 'student_id_card_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _customAmountController = TextEditingController();

  bool _isModerator = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final enrollment = context.read<AuthService>().currentUser?.enrollment;
    if (enrollment != null) {
      final role = await context.read<SupabaseService>().checkUserRole(enrollment);
      if (mounted && role == 'event_moderator') {
         setState(() => _isModerator = true);
      }
    }
  }

  Future<void> _launchUPI(BuildContext context, String amountStr) async {
    if (amountStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }
    
    // Get user enrollment for reference
    final enrollment = context.read<AuthService>().currentUser?.enrollment ?? 'Unknown';
    final note = 'MyGCET ($enrollment)'; // Short note with enrollment
    
    // Correct VPA as per user request (from working chips)
    const vpa = 'yusufgunderwala0@oksbi';
    const payeeName = 'MyGCET';
    
    // Properly encode parameters
    final uri = Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': vpa,
        'pn': payeeName,
        'am': amountStr,
        'tn': note,
        'cu': 'INR',
      },
    );
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback for some devices/versions
        await launchUrl(uri, mode: LaunchMode.externalApplication); 
      }
    } catch (e) {
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Could not launch UPI app: $e')),
         );
      }
    }
  }




  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final dataService = Provider.of<DataService>(context);
    final themeService = Provider.of<ThemeService>(context);
    final notificationService = Provider.of<NotificationService>(context);
    final user = authService.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;


    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF1C1C1E), const Color(0xFF000000)]
                    : [AppTheme.primaryBlue, const Color(0xFF1A237E)],
              ),
            ),
          ),
          // Decorative background elements - BOTH Light and Dark modes
          // Top left circles
          Positioned(
            top: -40,
            left: -40,
            child: _AnimatedShape(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.purple.withOpacity(0.15) : Colors.white.withOpacity(0.08), 
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: -20,
            left: -20,
            child: _AnimatedShape(
              delay: const Duration(milliseconds: 200),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.purple.withOpacity(0.05) : Colors.white.withOpacity(0.03),
                ),
              ),
            ),
          ),
          // Top right geometric
          Positioned(
            top: 60,
            right: 20,
            child: _AnimatedShape(
              delay: const Duration(milliseconds: 400),
              child: Transform.rotate(
                angle: 0.5,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark ? Colors.cyan.withOpacity(0.1) : Colors.white.withOpacity(0.06), 
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          // Subject icons scattered
          Positioned(
            top: 120,
            left: 30,
            child: _AnimatedShape(
              delay: const Duration(milliseconds: 600),
              child: Icon(
                Icons.calculate_outlined, 
                color: isDark ? Colors.purple.withOpacity(0.1) : Colors.white.withOpacity(0.05), 
                size: 40,
              ),
            ),
          ),
          Positioned(
            top: 180,
            right: 40,
            child: _AnimatedShape(
              delay: const Duration(milliseconds: 800),
              child: Icon(
                Icons.science_outlined, 
                color: isDark ? Colors.cyan.withOpacity(0.08) : Colors.white.withOpacity(0.05), 
                size: 35,
              ),
            ),
          ),
          Positioned(
            top: 250,
            left: 50,
            child: _AnimatedShape(
              delay: const Duration(milliseconds: 1000),
              child: Icon(
                Icons.code, 
                color: isDark ? Colors.purple.withOpacity(0.08) : Colors.white.withOpacity(0.04), 
                size: 30,
              ),
            ),
          ),
          Positioned(
            top: 80,
            right: 100,
            child: _AnimatedShape(
              delay: const Duration(milliseconds: 1200),
              child: Icon(
                Icons.memory, 
                color: isDark ? Colors.cyan.withOpacity(0.06) : Colors.white.withOpacity(0.04), 
                size: 25,
              ),
            ),
          ),
          // Hexagon decorations
          Positioned(
            top: 200,
            right: 15,
            child: _AnimatedShape(
              delay: const Duration(milliseconds: 1400),
              child: Transform.rotate(
                angle: 0.3,
                child: Container(
                  width: 40,
                  height: 46,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark ? Colors.purple.withOpacity(0.08) : Colors.white.withOpacity(0.05), 
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          // Small dots
          Positioned(
            top: 150,
            left: 100,
            child: _AnimatedShape(
              delay: const Duration(milliseconds: 1600),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.cyan.withOpacity(0.15) : Colors.white.withOpacity(0.1),
                ),
              ),
            ),
          ),
          Positioned(
            top: 220,
            right: 80,
            child: _AnimatedShape(
              delay: const Duration(milliseconds: 1800),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.purple.withOpacity(0.12) : Colors.white.withOpacity(0.08),
                ),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Profile',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

// ... (keep existing imports)

              // Profile Header
              FadeInSlide(
                duration: const Duration(milliseconds: 600),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: ClipOval(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                              child: Center(
                                child: Text(
                                  user?.name.isNotEmpty == true ? user!.name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join().toUpperCase() : 'ST',
                                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Name
                      Text(
                        user?.name ?? 'Student',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                        ),
                        child: Text(
                          user?.enrollment ?? 'N/A',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Scrollable Content
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade50,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Stats Row
                          FadeInSlide(
                            delay: const Duration(milliseconds: 100),
                            child: Row(
                              children: [
                                Expanded(child: _buildStatItem('${dataService.overallAttendance.toStringAsFixed(0)}%', 'Attendance', Icons.check_circle_outline, dataService.overallAttendance >= 75 ? Colors.green : Colors.orange, isDark)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildStatItem('${dataService.materials.length}', 'Materials', Icons.folder_outlined, Colors.blue, isDark)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildStatItem('${dataService.attendance.length}', 'Subjects', Icons.book_outlined, Colors.purple, isDark)),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),
                          
                          // Academic Details
                          FadeInSlide(
                            delay: const Duration(milliseconds: 200),
                            child: _buildInfoCard('Academic Details', Icons.school, [
                              _buildInfoRow('Branch', user?.branch ?? 'N/A', isDark),
                              _buildEditableInfoRow('Semester', user?.semester ?? 'N/A', isDark, () {
                                _showEditSemesterDialog(context, authService, user?.semester ?? '');
                              }),
                              _buildInfoRow('Section', user?.section ?? 'N/A', isDark),
                            ], isDark),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Quick Actions
                          FadeInSlide(
                            delay: const Duration(milliseconds: 300),
                            child: _buildInfoCard('Quick Actions', Icons.flash_on, [
                              _buildActionRow('View ID Card', Icons.badge_outlined, Colors.blue, () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentIdCardScreen()));
                              }, isDark),
                              _buildActionRow('View Results', Icons.analytics_outlined, Colors.deepOrange, () {
                                Navigator.pushNamed(context, AppRoutes.results);
                              }, isDark),
                              if (_isModerator)
                                _buildActionRow('Manage Events (Moderator)', Icons.event_available, Colors.purpleAccent, () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCreateEventScreen()));
                                }, isDark),
                              if (user?.id == 'admin')
                                _buildActionRow('Admin Panel', Icons.admin_panel_settings_outlined, Colors.red, () {
                                  Navigator.pushNamed(context, AppRoutes.admin);
                                }, isDark),
                            ], isDark),
                          ),

                          const SizedBox(height: 16),
                          
                          
                          // Theme Mode Selector
                          FadeInSlide(
                            delay: const Duration(milliseconds: 500),
                            child: _buildInfoCard('Theme Mode', Icons.palette_outlined, [
                              Row(
                                children: [
                                  Expanded(child: _buildThemeButton('System', themeService.themeMode == ThemeMode.system, () => themeService.setThemeMode(ThemeMode.system), isDark)),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildThemeButton('Light', themeService.themeMode == ThemeMode.light, () => themeService.setThemeMode(ThemeMode.light), isDark)),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildThemeButton('Dark', themeService.themeMode == ThemeMode.dark, () => themeService.setThemeMode(ThemeMode.dark), isDark)),
                                ],
                              ),
                            ], isDark),
                          ),

                          const SizedBox(height: 16),

                          // Meet the Developers
                          FadeInSlide(
                            delay: const Duration(milliseconds: 600),
                            child: _buildInfoCard('Meet the Developers', Icons.code, [
                              _buildDeveloperRow('Abdullah Kapadia', 'Information Technology (IT)', 'A', Colors.orange, isDark),
                              const SizedBox(height: 12),
                              _buildDeveloperRow('Yusuf Gundarwala', 'Computer Department', 'Y', Colors.amber, isDark),
                              const SizedBox(height: 20),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () async {
                                    final Uri emailLaunchUri = Uri(
                                      scheme: 'mailto',
                                      path: 'mygcet.official.53@gmail.com',
                                      query: 'subject=GCET Tracker Support',
                                    );
                                    try {
                                      await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
                                    } catch (e) {
                                      debugPrint('Could not launch email: $e');
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBlue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.mail_rounded, color: AppTheme.primaryBlue, size: 24),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Have queries or found a bug?',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark ? Colors.white : Colors.black87,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'mygcet.official.53@gmail.com',
                                                style: TextStyle(
                                                  color: AppTheme.primaryBlue,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ], isDark),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Logout
                          FadeInSlide(
                            delay: const Duration(milliseconds: 700),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _showLogoutDialog(context),
                                icon: const Icon(Icons.logout, size: 20),
                                label: const Text(
                                  'Sign Out',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    inherit: false,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // App version
                          FadeInSlide(
                            delay: const Duration(milliseconds: 800),
                            child: Text(
                              'MyGCET v3.0',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white38 : Colors.grey.shade500,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Support Us Section
                          FadeInSlide(
                            delay: const Duration(milliseconds: 900),
                            child: _buildSupportSection(isDark),
                          ),
                          
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      ),
    );
  }
  
  Widget _buildStatItem(String value, String label, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<Widget> children, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: AppTheme.primaryBlue, size: 20)),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildEditableInfoRow(String label, String value, bool isDark, VoidCallback onEdit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value.isEmpty ? 'Not set' : value, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.edit, size: 16, color: AppTheme.primaryBlue),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditSemesterDialog(BuildContext context, AuthService authService, String currentValue) {
    final controller = TextEditingController(text: currentValue);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        title: Text('Edit Semester', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'e.g., 5 or V',
            hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white60 : Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newSemester = controller.text.trim();
              if (authService.currentUser != null) {
                final updatedUser = authService.currentUser!.copyWith(semester: newSemester);
                await authService.updateUser(updatedUser);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(String title, IconData icon, Color color, VoidCallback onTap, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, color: isDark ? Colors.white54 : Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeButton(String label, bool isSelected, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeveloperRow(String name, String dept, String initial, Color color, bool isDark) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Text(initial, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
              Text(dept, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade600)),
            ],
          ),
        ),
      ],
    );
  }

  void _showIDCardDialog(BuildContext context, dynamic user, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryBlue, Color(0xFF1A237E)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/images/My GCET_20251225_134706_0000.png', height: 40, errorBuilder: (_, __, ___) => const Icon(Icons.school, color: Colors.white, size: 40)),
                  const Text('STUDENT ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 20),
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Center(
                  child: Text(
                    user?.name.isNotEmpty == true ? user!.name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join().toUpperCase() : 'ST',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Name
              Text(
                user?.name ?? 'Student',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                user?.enrollment ?? 'N/A',
                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
              ),
              const SizedBox(height: 16),
              // Details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildIDCardRow('Branch', user?.branch ?? 'N/A'),
                    _buildIDCardRow('Semester', user?.semester ?? 'N/A'),
                    _buildIDCardRow('Section', user?.section ?? 'N/A'),
                    _buildIDCardRow('Email', user?.email ?? 'N/A'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Close button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIDCardRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
             onPressed: () {
               Provider.of<AuthService>(context, listen: false).logout();
               Provider.of<DataService>(context, listen: false).clearData();
               Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
             },
             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
             child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF667eea).withOpacity(0.15),
            const Color(0xFF764ba2).withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF667eea).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.pink.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite, color: Colors.pink, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            'Support Us',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'If you find this app helpful, consider supporting the developers!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          
          // Recommended Amounts
          Text(
            'Recommended Amount',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDonationChip(53, isDark),
              _buildDonationChip(153, isDark),
              _buildDonationChip(253, isDark),
            ],
          ),
          
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          
          // Custom Amount Section
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Or enter custom amount:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customAmountController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Amount (₹)',
                      hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400),
                      prefixText: '₹ ',
                      prefixStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                      isDense: true,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _launchUPI(context, _customAmountController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Pay', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildDonationChip(int amount, bool isDark) {
    return InkWell(
      onTap: () => _launchUPI(context, amount.toString()),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF667eea).withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667eea).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              '₹$amount',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF667eea),
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showDonateDialog(bool isDark) {
    final TextEditingController _customAmountController = TextEditingController(); // NEW

  Future<void> _launchUPI(BuildContext context, String amount) async {
    if (amount.isEmpty) return;
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    final enrollment = user?.enrollment ?? 'Unknown';
    final name = user?.name ?? 'Student';
    
    // Construct UPI URL
    // pn: Payee Name (e.g. MyGCET Support)
    // pa: Payee VPA (using a placeholder, user should update this)
    // am: Amount
    // tn: Transaction Note (Enrollment + MyGCET)
    
    // You must replace 'example@upi' with the actual VPA
    const vpa = '8460655027@kotak'; 
    const payeeName = 'MyGCET Support';
    
    final uri = Uri.parse(
      'upi://pay?pa=$vpa&pn=$payeeName&am=$amount&tn=$enrollment MyGCET'
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback or external application mode
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Could not launch UPI app: $e')),
        );
      }
    }
  }
    final remarkController = TextEditingController(text: 'MyGCET App Support');
    final amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.favorite, color: Colors.pink, size: 24),
            const SizedBox(width: 12),
            const Text('Support Us'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (₹)',
                hintText: 'Enter amount',
                prefixIcon: const Icon(Icons.currency_rupee),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                   for (final amount in ['53', '153', '253'])
                     Padding(
                       padding: const EdgeInsets.only(right: 8),
                       child: ActionChip(
                         label: Text('₹$amount'),
                         backgroundColor: Colors.pink.withOpacity(0.1),
                         labelStyle: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
                         onPressed: () => amountController.text = amount,
                         side: BorderSide.none,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                       ),
                     ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: remarkController,
              decoration: InputDecoration(
                labelText: 'Remark (Optional)',
                prefixIcon: const Icon(Icons.message_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = amountController.text.trim();
              final remark = remarkController.text.trim();
              
              if (amount.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter an amount')),
                );
                return;
              }
              
              // Create UPI deep link
              final upiUrl = 'upi://pay?pa=yusufgunderwala0@oksbi&pn=MyGCET%20Support&am=$amount&cu=INR&tn=${Uri.encodeComponent(remark)}';
              
              try {
                final uri = Uri.parse(upiUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No UPI app found. Please use the UPI ID manually.')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
            ),
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );
  }
}

/// Animated decoration shape with subtle floating/pulsing animation
class _AnimatedShape extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _AnimatedShape({required this.child, this.delay = Duration.zero});

  @override
  State<_AnimatedShape> createState() => _AnimatedShapeState();
}

class _AnimatedShapeState extends State<_AnimatedShape> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _opacity = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _scale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
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
        return Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scale: _scale.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}
