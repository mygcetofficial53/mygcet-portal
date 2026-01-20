import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../../core/theme/app_theme.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../services/supabase_service.dart';
import '../../services/auth_service.dart';
import 'admin_login_screen.dart';
import 'admin_create_event_screen.dart';
import 'admin_notification_screen.dart';
import 'admin_cms_screen.dart';
import 'admin_polls_screen.dart';
import 'admin_feedback_screen.dart';
import 'admin_role_manager_screen.dart';
import 'admin_event_approval_screen.dart';
import 'admin_analytics_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Stats
  Map<String, dynamic> _userStats = {
    'total': 0, 
    'active': 0,
    'departments': {},
  };
  bool _isLoadingStats = true;
  bool _isMaintenanceMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoadingStats = true);
    final supabase = Provider.of<SupabaseService>(context, listen: false);
    
    try {
      await Future.wait([
        supabase.fetchUserStats().then((data) {
          if (mounted) setState(() => _userStats = data);
        }),
        supabase.isMaintenanceModeEnabled().then((enabled) {
          if (mounted) setState(() => _isMaintenanceMode = enabled);
        }),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
    
    if (mounted) setState(() => _isLoadingStats = false);
  }

  @override
  Widget build(BuildContext context) {
    // Reference image color palette
    // Background: #121212 or very dark blue #0F172A
    // Cards: #1E293B or similar rounded
    
    return Scaffold(
      backgroundColor: const Color(0xFF101014), // Dark background like image
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'ADMIN PANEL',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
           IconButton(
             onPressed: () async {
                await Provider.of<AuthService>(context, listen: false).logout();
                if (mounted) {
                   Navigator.pushReplacement(
                     context,
                     MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                   );
                }
             },
             icon: const Icon(Icons.logout, color: Colors.white54),
           ),
        ],
      ),
      body: _isLoadingStats 
        ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                // "Sync Data" Button at top (like image)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  child: ElevatedButton.icon(
                    onPressed: _loadDashboardData,
                    icon: const Icon(Icons.sync, color: Colors.white70),
                    label: const Text('Sync Data', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1C1C1E),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                  ),
                ),
                
                // Stats Grid (Attendance/OD Classes style)
                Row(
                  children: [
                    Expanded(
                      child: _buildSquareStatCard(
                        title: 'Total Users',
                        value: '${_userStats['total']}',
                        subtitle: 'Registered',
                        progress: 0.76, // Hardcoded visual for style like image
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSquareStatCard(
                        title: 'Active Users',
                        value: '${_userStats['active']}',
                        subtitle: 'Online Today',
                        isIcon: true,
                        icon: Icons.notifications, // Using bell icon as requested by style
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // List Items (Like "Academic Calendar")
                _buildActionTile(
                  icon: Icons.event,
                  title: 'Manage Events',
                  subtitle: 'Create or delete events',
                  color: Colors.blueAccent,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCreateEventScreen())); // Or list
                  },
                ),
                _buildActionTile(
                  icon: Icons.notifications_active,
                  title: 'Send Notification',
                  subtitle: 'Broadcast alerts to students',
                  color: Colors.pinkAccent,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminNotificationScreen()));
                  },
                ),
                _buildActionTile(
                  icon: Icons.tune,
                  title: 'App Customizer',
                  subtitle: 'Banner & Theme Control',
                  color: Colors.amberAccent,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCmsScreen()));
                  },
                ),
                _buildActionTile(
                  icon: Icons.poll_outlined,
                  title: 'Manage Polls',
                  subtitle: 'Create & View Results',
                  color: Colors.purpleAccent,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPollsScreen()));
                  },
                ),
                _buildActionTile(
                  icon: Icons.chat_bubble_outline,
                  title: 'View User Feedback',
                  subtitle: 'Read students reviews',
                  color: Colors.tealAccent,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminFeedbackScreen()));
                  },
                ),
                _buildActionTile(
                  icon: Icons.search,
                  title: 'Search User',
                  subtitle: 'Check version & branch',
                  color: Colors.cyanAccent,
                  onTap: _showSearchUserDialog,
                ),
                _buildActionTile(
                  icon: Icons.lock_person,
                  title: 'Restrict User',
                  subtitle: 'Block student access',
                  color: Colors.redAccent,
                  onTap: _showRestrictUserDialog,
                ),
                _buildActionTile(
                  icon: Icons.security,
                  title: 'Manage Roles',
                  subtitle: 'Add Event Moderators',
                  color: Colors.indigoAccent,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminRoleManagerScreen()));
                  },
                ),
                _buildActionTile(
                  icon: Icons.verified_user,
                  title: 'Verification Queue',
                  subtitle: 'Approve Pending Events',
                  color: Colors.amber,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminEventApprovalScreen()));
                  },
                ),
                _buildActionTile(
                  icon: Icons.analytics_outlined,
                  title: 'App Analytics',
                  subtitle: 'Usage Heatmap & Stats',
                  color: Colors.pinkAccent,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAnalyticsScreen()));
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Maintanence Mode Toggle
                 Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SwitchListTile(
                    title: const Text('Maintenance Mode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(_isMaintenanceMode ? 'App is LOCKED' : 'App is Active', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    value: _isMaintenanceMode,
                    activeColor: Colors.redAccent,
                    onChanged: (val) => _showMaintenanceDialog(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    secondary: Icon(Icons.security, color: _isMaintenanceMode ? Colors.redAccent : Colors.greenAccent),
                  ),
                ),
                
                const SizedBox(height: 40),
                // Footer
                /*
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildBottomIcon(Icons.home, 'Home', true),
                    _buildBottomIcon(Icons.bar_chart, 'Stats', false),
                    _buildBottomIcon(Icons.settings, 'Settings', false),
                  ],
                )
                */
              ],
            ),
          ),
    );
  }

  Widget _buildSquareStatCard({
    required String title, required String value, required String subtitle, 
    double? progress, bool isIcon = false, IconData? icon, required Color color
  }) {
    return Container(
      // Removed fixed height: 160 to prevent overflow
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isIcon)
            Icon(icon, size: 40, color: Colors.white)
          else 
            SizedBox(
              width: 50, height: 50, // Reduced from 60 to save space
              child: Stack(
                children: [
                  CircularProgressIndicator(
                    value: progress ?? 0.0,
                    strokeWidth: 2,
                    backgroundColor: Colors.white12,
                    color: Colors.white,
                  ),
                  Center(
                    child: Container(width: 40, height: 40, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.transparent))
                  )
                ],
              ),
            ),
          const SizedBox(height: 12), // Reduced spacing
          FittedBox( // Prevent text overflow
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon, required String title, required String subtitle, 
    required Color color, required VoidCallback onTap
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
      ),
    );
  }

  /*
  Widget _buildBottomIcon(IconData icon, String label, bool isSelected) {
    return Column(
      children: [
        Icon(icon, color: isSelected ? Colors.white : Colors.white24, size: 28),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white24, fontSize: 10)),
      ],
    );
  }
  */

  // --- Dialogs (Reused Logic) ---

  void _showMaintenanceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: Text(_isMaintenanceMode ? 'Disable Maintenance Mode?' : 'Enable Maintenance Mode?', style: const TextStyle(color: Colors.white)),
        content: Text(
           _isMaintenanceMode 
               ? 'Users will be able to access the app again.'
               : 'DANGER: This will lock all users out of the app immediately.',
           style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await Provider.of<SupabaseService>(context, listen: false).setMaintenanceMode(!_isMaintenanceMode);
              if (mounted) {
                Navigator.pop(ctx);
                _loadDashboardData();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _isMaintenanceMode ? Colors.green : Colors.red),
            child: Text(_isMaintenanceMode ? 'Enable App' : 'LOCK APP', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRestrictUserDialog() {
    final enrollmentController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Restrict User Access', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: enrollmentController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enrollment Number',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
             onPressed: () async {
               if (enrollmentController.text.trim().isNotEmpty) {
                 await Provider.of<SupabaseService>(context, listen: false).unrestrictUser(enrollmentController.text.trim());
                 if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unblocked')));
                 }
               }
             },
             child: const Text('Unblock', style: TextStyle(color: Colors.greenAccent)),
          ),
          ElevatedButton(
            onPressed: () async {
               if (enrollmentController.text.trim().isNotEmpty) {
                 await Provider.of<SupabaseService>(context, listen: false).restrictUser(enrollmentController.text.trim());
                 if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restricted')));
                 }
               }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Restrict'),
          ),
        ],
      ),
    );
  }

  void _showSearchUserDialog() {
    final enrollmentController = TextEditingController();
    Map<String, dynamic>? searchResult;
    bool isSearching = false;
    String? searchError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1C1C1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Search Student', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: enrollmentController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter Enrollment No.',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: isSearching 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.search, color: Colors.cyanAccent),
                      onPressed: () async {
                        if (enrollmentController.text.isEmpty) return;
                        setDialogState(() {
                          isSearching = true;
                          searchError = null;
                          searchResult = null;
                        });
                        
                        final result = await Provider.of<SupabaseService>(context, listen: false)
                            .lookupStudent(enrollmentController.text.trim());
                            
                        setDialogState(() {
                          isSearching = false;
                          if (result != null) {
                            searchResult = result;
                          } else {
                            searchError = 'User not found';
                          }
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (searchError != null)
                  Text(searchError!, style: const TextStyle(color: Colors.redAccent)),
                  
                if (searchResult != null) ...[
                  Text('Name: ${searchResult!['name']}', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text('Branch: ${searchResult!['branch'] ?? 'N/A'}', 
                      style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('App Version: ${searchResult!['app_version'] ?? 'Old / Unknown'}', 
                      style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Last Login: ${searchResult!['last_login'] != null ? DateFormat('MMM d, h:mm a').format(DateTime.parse(searchResult!['last_login'])) : 'N/A'}', 
                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ]
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            ],
          );
        }
      ),
    );
  }
}
