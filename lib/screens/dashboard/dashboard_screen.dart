import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart'; // Added Lottie import
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../services/holiday_service.dart';
import '../../services/timetable_service.dart';
import '../../services/notification_service.dart';
import '../../services/weather_service.dart'; // Added WeatherService import
import '../../widgets/stat_card.dart';
import '../../widgets/feature_tile.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/dock_nav_bar.dart';
import '../../widgets/animated_gradient_background.dart';
import '../../widgets/offline_banner.dart';
import '../events/user_events_screen.dart';
import '../../widgets/animations/fade_in_slide.dart';
import '../../widgets/weather_visuals.dart';
import '../../services/theme_service.dart';
import '../../services/announcement_service.dart';
import '../../services/supabase_service.dart';
import '../../models/announcement_model.dart';
import '../../widgets/galaxy_spiral_refresher.dart';
import '../../widgets/poll_card.dart';
import '../maintenance_screen.dart';
import '../../widgets/poll_card.dart';
import '../../widgets/app_feedback_card.dart';
import '../maintenance_screen.dart';
import '../../core/constants/app_constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  bool _isRefreshing = false;
  Timer? _refreshTimer;
  Map<String, dynamic> _cmsConfig = {};
  int _easterEggTapCount = 0; // Secret tap counter 🥚

  @override
  void initState() {
    super.initState();
    // Refresh every minute to keep "Next Class" updated
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
    // Defer loading to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isRefreshing = true);
    final authService = context.read<AuthService>();
    final dataService = context.read<DataService>();
    final holidayService = context.read<HolidayService>();
    final weatherService = context.read<WeatherService>(); // Get WeatherService
    final supabaseService = context.read<SupabaseService>();

    // 1. Check Maintenance Mode
    try {
      final isMaintenance = await supabaseService.isMaintenanceModeEnabled();
      if (isMaintenance && mounted) {
        // Navigate to maintenance screen and remove back stack
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (_) => const MaintenanceScreen()), 
          (route) => false
        );
        return; 
      }
    } catch (e) {
      debugPrint('Error checking maintenance mode: $e');
    }

    // Set the GMS service from auth service
    dataService.setGmsService(authService.gmsService);

    await Future.wait([
      // Pass current user so registered courses can be used as fallback
      dataService.fetchAllData(student: authService.currentUser),
      holidayService.fetchHolidays(),
      weatherService.fetchWeather(),
      // Fetch Supabase notifications (Targeted)
      supabaseService.fetchNotifications(userBranch: authService.currentUser?.branch),
      // Fetch CMS Config
      supabaseService.getAppThemeConfig().then((config) {
        if (mounted) {
           setState(() => _cmsConfig = config);
           _checkMinVersion(config['min_version']);
        } 
      }),
    ]);

    // Feedback check removed from here (Moved to Post-Event)
    
    // If data was fetched successfully (not offline), clear the offline flag in auth
    if (!dataService.isOffline) {
      authService.setOnline();
    } else {
      // If fetching failed/fell back to cache, show offline banner
      authService.setOffline();
    }
    
    // Re-check maintenance mode after fetch (in case it changed during fetch)
    try {
      final isMaintenance = await supabaseService.isMaintenanceModeEnabled();
      if (isMaintenance && mounted) {
         Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (_) => const MaintenanceScreen()), 
          (route) => false
        );
      }
    } catch (_) {}
    
    setState(() => _isRefreshing = false);
    
    // Check for low attendance and show alert
    _checkLowAttendance(dataService);
  }

  Future<void> _checkFeedback(String enrollment, SupabaseService supabase) async {
    // Check if validation/skipping logic is stored locally first to avoid unnecessary API calls
    // But for now, we check Supabase to be sure.
    final hasSubmitted = await supabase.hasUserSubmittedFeedback(enrollment);
    if (!hasSubmitted && mounted) {
      // Small delay to let UI settle
      await Future.delayed(const Duration(seconds: 2)); 
      if (!mounted) return;
      _showFeedbackDialog(enrollment, supabase);
    }
  }

  void _showFeedbackDialog(String enrollment, SupabaseService supabase) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('We value your opinion!', style: TextStyle(color: Colors.white)),
        content: const Text('Do you like the App?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showFeedbackInput(ctx, enrollment, supabase); // No -> Ask for changes
            },
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
               supabase.submitFeedback(enrollment: enrollment, liked: true);
               Navigator.pop(ctx);
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Thank you for your feedback! ❤️')),
               );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
            child: const Text('Yes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }



  void _showFeedbackInput(BuildContext context, String enrollment, SupabaseService supabase) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Help us improve', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('What changes do you need?', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type your suggestions...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
               if (controller.text.trim().isNotEmpty) {
                 supabase.submitFeedback(
                   enrollment: enrollment, 
                   liked: false, 
                   message: controller.text.trim()
                 );
                 Navigator.pop(ctx);
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Feedback submitted. We will look into it!')),
                 );
               }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _checkLowAttendance(DataService dataService) async {
    final notificationService = context.read<NotificationService>();
    
    // Check if alert was already shown today
    final alreadyShown = await notificationService.wasLowAttendanceAlertShownToday();
    if (alreadyShown) return;
    
    // Find subjects below 75%
    final lowSubjects = dataService.attendance.where((a) => a.percentage < 75).toList();
    
    if (lowSubjects.isEmpty || !mounted) return;
    
    // Sort by percentage to find worst
    lowSubjects.sort((a, b) => a.percentage.compareTo(b.percentage));
    final worst = lowSubjects.first;
    
    // Show alert dialog
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.dangerRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_rounded, color: AppTheme.dangerRed, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Attendance Alert'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${lowSubjects.length} subject(s) need attention!',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ...lowSubjects.take(3).map((subject) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: subject.percentage < 70 ? AppTheme.dangerRed : AppTheme.warningOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      subject.subjectName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${subject.percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: subject.percentage < 70 ? AppTheme.dangerRed : AppTheme.warningOrange,
                    ),
                  ),
                ],
              ),
            )),
            if (lowSubjects.length > 3)
              Text(
                '... and ${lowSubjects.length - 3} more',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: AppTheme.primaryBlue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Need ${worst.classesNeededFor75} more classes in ${worst.subjectCode} for 75%',
                      style: const TextStyle(fontSize: 12, color: AppTheme.primaryBlue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await notificationService.dismissLowAttendanceAlertForToday();
              Navigator.pop(ctx);
            },
            child: const Text("Don't show today"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, AppRoutes.attendance);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;
    final student = Provider.of<AuthService>(context).currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true, 
      body: Stack(
        children: [
          // Background
          const Positioned.fill(
            child: AnimatedGradientBackground(),
          ),
          
          // Content with Refresher
          Positioned.fill(
            child: GalaxySpiralRefresher(
              onRefresh: () async {
                await Provider.of<DataService>(context, listen: false).fetchAllData();
              },
              slivers: [
                  // CMS Banner
                  if (_cmsConfig['banner_visible'] == true)
                    SliverToBoxAdapter(
                      child: FadeInSlide(
                        duration: const Duration(milliseconds: 600),
                        child: Builder(
                          builder: (context) {
                            final topPadding = MediaQuery.paddingOf(context).top;
                            return Container(
                              margin: EdgeInsets.fromLTRB(20, topPadding + 10, 20, 0),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(int.parse(_cmsConfig['theme_color'] ?? '0xFF3B82F6')),
                                    Color(int.parse(_cmsConfig['theme_color'] ?? '0xFF3B82F6')).withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.stars_rounded, color: Colors.white, size: 28),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _cmsConfig['banner_text'] ?? 'Welcome!',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // Header
                  SliverToBoxAdapter(
                    child: FadeInSlide(
                      duration: const Duration(milliseconds: 600),
                      child: _buildHeader(),
                    ),
                  ),

                  // Poll Card
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: PollCard(),
                    ),
                  ),
                  
                  // Announcements Section
                  SliverToBoxAdapter(
                    child: FadeInSlide(
                      delay: const Duration(milliseconds: 50),
                      duration: const Duration(milliseconds: 600),
                      child: _buildAnnouncementSection(),
                    ),
                  ),
                  
                  // Stats Overview using QuickStats 
                  SliverToBoxAdapter(
                    child: FadeInSlide(
                      delay: const Duration(milliseconds: 150),
                      duration: const Duration(milliseconds: 600),
                      child: _buildQuickStats(),
                    ),
                  ),

                  // Upcoming Holidays
                  SliverToBoxAdapter(
                    child: FadeInSlide(
                      delay: const Duration(milliseconds: 200),
                      duration: const Duration(milliseconds: 600),
                      child: _buildHolidaysSection(),
                    ),
                  ),
      
                  // Your Subjects Section
                  SliverToBoxAdapter(
                    child: FadeInSlide(
                      delay: const Duration(milliseconds: 300),
                      duration: const Duration(milliseconds: 600),
                      child: _buildSubjectsSection(),
                    ),
                  ),
      
                  // Features Grid
                  SliverToBoxAdapter(
                    child: FadeInSlide(
                      delay: const Duration(milliseconds: 400),
                      duration: const Duration(milliseconds: 600),
                      child: _buildFeaturesSection(),
                    ),
                  ),
      
                  // Coming Soon Feature
                  SliverToBoxAdapter(
                    child: FadeInSlide(
                      delay: const Duration(milliseconds: 500),
                      duration: const Duration(milliseconds: 600),
                      child: _buildComingSoonCard(),
                    ),
                  ),
      
                  // Recent Activity
                  SliverToBoxAdapter(
                    child: FadeInSlide(
                      delay: const Duration(milliseconds: 600),
                      duration: const Duration(milliseconds: 600),
                      child: _buildRecentActivity(),
                    ),
                  ),

                  // App Feedback Section (Botttom of Home)
                  SliverToBoxAdapter(
                    child: FadeInSlide(
                      delay: const Duration(milliseconds: 700),
                      duration: const Duration(milliseconds: 600),
                      child: const Padding(
                        padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: AppFeedbackCard(),
                      ),
                    ),
                  ),
      
                  // Extra padding for bottom nav
                  // Bottom spacing for nav bar
                  SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildHeader() {
    return Consumer2<AuthService, DataService>(
      builder: (context, authService, dataService, child) {
        final user = authService.currentUser;
        final isOnTrack = dataService.overallAttendance >= 75;
        
        return Container(
          height: 120, // Minimized gap with announcement
          margin: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 10, 20, 0),
          child: Stack(
            children: [
              // Main Content
              Positioned.fill(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Offline Banner
                    if (authService.isOffline)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: OfflineChip(isOffline: authService.isOffline),
                      ),
                      
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar on left - Fixed edges with proper clipping
                        GestureDetector(
                          onTap: () {
                            _easterEggTapCount++;
                            if (_easterEggTapCount >= 7) {
                              _easterEggTapCount = 0;
                              _showEasterEgg();
                            }
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Image.asset(
                                'assets/images/My GCET_20251225_134706_0000.png',
                                fit: BoxFit.cover,
                                width: 60,
                                height: 60,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    user?.name.isNotEmpty == true ? user!.name[0] : 'U',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppTheme.primaryBlue),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Info & Name with shadows for visibility
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '${_getGreeting()},',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                user?.name.toUpperCase() ?? 'KAPADIA ABDULLA A...',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  height: 1.2,
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.4),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              // Status Badge - Transparent/Outlined style like image
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (isOnTrack ? Colors.greenAccent : Colors.orangeAccent).withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: (isOnTrack ? Colors.greenAccent : Colors.orangeAccent).withOpacity(0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isOnTrack ? Icons.check_circle_rounded : Icons.info_outline,
                                      size: 14,
                                      color: isOnTrack ? Colors.greenAccent : Colors.orangeAccent,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isOnTrack ? 'On Track' : 'Not On Track',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isOnTrack ? Colors.greenAccent : Colors.orangeAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Logout Button with better visibility
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: () async {
                              await context.read<AuthService>().logout();
                              context.read<DataService>().clearData();
                              if (context.mounted) {
                                Navigator.pushReplacementNamed(context, AppRoutes.login);
                              }
                            },
                            icon: Icon(
                              Icons.logout,
                              color: Colors.white,
                              size: 22,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(10),
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }



  Widget _buildQuickStats() {
    return Consumer<DataService>(
      builder: (context, dataService, child) {
        if (dataService.isLoading && dataService.attendance.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ShimmerLoading(type: ShimmerType.stats, itemCount: 3),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Attendance',
                    value: '${dataService.overallAttendance.toStringAsFixed(1)}%',
                    icon: Icons.check_circle_outline,
                    gradient: AppTheme.attendanceGradient,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FutureBuilder(
                    future: TimetableService().getNextClass(),
                    builder: (context, snapshot) {
                      String nextClass = '-';
                      
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        nextClass = '...';
                      } else if (snapshot.hasData && snapshot.data != null) {
                        final slot = snapshot.data!;
                        // Full subject name, StatCard handles sizing
                        nextClass = slot.subject;
                      }
                      
                      return StatCard(
                        title: 'Next Class',
                        value: nextClass,
                        icon: Icons.schedule_outlined,
                        gradient: AppTheme.cardGradient,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Subjects',
                    value: '${dataService.attendance.length}',
                    icon: Icons.book_outlined,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnnouncementSection() {
    return Consumer<SupabaseService>(
      builder: (context, supabaseService, child) {
        final notifications = supabaseService.notifications;

        if (notifications.isEmpty) {
          return const SizedBox.shrink();
        }

        // Convert Supabase notification to Announcement model
        final latestNotif = notifications.first;
        final latestAnnouncement = Announcement(
          id: latestNotif['id']?.toString() ?? '0',
          title: latestNotif['title'] ?? 'New Message',
          message: latestNotif['message'] ?? '',
          type: AnnouncementType.values.firstWhere(
            (e) => e.name == (latestNotif['type'] ?? 'info'),
            orElse: () => AnnouncementType.info,
          ),
          date: DateTime.tryParse(latestNotif['created_at']?.toString() ?? '') ?? DateTime.now(),
          isRead: false,
        );

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: _GlassmorphicAnnouncementBanner(
            latestAnnouncement: latestAnnouncement,
            totalCount: notifications.length,
            unreadCount: notifications.length, // Simplified unread count
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.announcements);
            },
          ),
        );
      },
    );
  }

  Widget _buildHolidaysSection() {
    return Consumer<HolidayService>(
      builder: (context, holidayService, child) {
        final upcomingHolidays = holidayService.upcomingHolidays.take(2).toList();

        if (upcomingHolidays.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.celebration,
                    color: AppTheme.warningOrange,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Upcoming Holidays',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.calendar);
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: upcomingHolidays.length,
                itemBuilder: (context, index) {
                  final holiday = upcomingHolidays[index];
                  return _HolidayCard(
                    name: holiday.name,
                    localName: holiday.localName,
                    date: holiday.dateTime,
                    daysUntil: holiday.daysUntil,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubjectsSection() {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final user = authService.currentUser;
        final courses = user?.registeredCourses ?? [];

        if (courses.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    color: AppTheme.primaryBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Your Subjects (${courses.length})',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  if (user?.semester.isNotEmpty == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user!.semester,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    final isLab = course.type.toLowerCase().contains('lab') || 
                                  course.type.toLowerCase().contains('practical');
                    return Container(
                      width: 200,
                      margin: EdgeInsets.only(right: index < courses.length - 1 ? 12 : 0),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isLab 
                              ? [const Color(0xFF11998e), const Color(0xFF38ef7d)]
                              : [const Color(0xFF667eea), const Color(0xFF764ba2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (isLab ? const Color(0xFF11998e) : const Color(0xFF667eea))
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  course.code,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isLab ? 'Lab' : 'Theory',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            course.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeaturesSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Access',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              FeatureTile(
                title: 'Events',
                subtitle: 'Coming Soon',
                icon: Icons.local_activity,
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.hourglass_empty, color: Colors.white),
                          const SizedBox(width: 12),
                          const Expanded(child: Text('Events feature is coming soon!')),
                        ],
                      ),
                      backgroundColor: const Color(0xFF8B5CF6),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              ),
              FeatureTile(
                title: 'Attendance',
                subtitle: 'View subject-wise',
                icon: Icons.calendar_today,
                color: const Color(0xFF11998e),
                onTap: () => Navigator.pushNamed(context, AppRoutes.attendance),
              ),
              FeatureTile(
                title: 'Materials',
                subtitle: 'Study resources',
                icon: Icons.folder_outlined,
                color: const Color(0xFF667eea),
                onTap: () => Navigator.pushNamed(context, AppRoutes.materials),
              ),
              FeatureTile(
                title: 'Results',
                subtitle: 'Your results',
                icon: Icons.analytics_outlined,
                color: const Color(0xFFf093fb),
                onTap: () => Navigator.pushNamed(context, AppRoutes.results),
              ),
              FeatureTile(
                title: 'Calendar',
                subtitle: 'Events & holidays',
                icon: Icons.event_outlined,
                color: const Color(0xFF4facfe),
                onTap: () => Navigator.pushNamed(context, AppRoutes.calendar),
              ),
              FeatureTile(
                title: 'Profile',
                subtitle: 'Your details',
                icon: Icons.person_outline,
                color: const Color(0xFF43e97b),
                onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
              ),
              FeatureTile(
                title: 'Timetable',
                subtitle: 'Weekly schedule',
                icon: Icons.schedule_outlined,
                color: const Color(0xFFFA709A),
                onTap: () => Navigator.pushNamed(context, AppRoutes.timetable),
              ),
              FeatureTile(
                title: 'Exam Papers',
                subtitle: 'Mid Sem Papers',
                icon: Icons.description_outlined,
                color: const Color(0xFFFF9A9E),
                onTap: () => _showExamPapersDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFD946EF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background decorations
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            // Confetti/sparkle decorations
            Positioned(
              top: 20,
              right: 60,
              child: Icon(Icons.auto_awesome, color: Colors.white.withOpacity(0.3), size: 24),
            ),
            Positioned(
              bottom: 30,
              right: 30,
              child: Icon(Icons.celebration, color: Colors.white.withOpacity(0.2), size: 32),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Coming Soon badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4ADE80),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'COMING SOON',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.event_available, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Event Registration',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'One-tap registration for all college events',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Feature pills
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFeaturePill(Icons.qr_code, 'Digital Pass'),
                      _buildFeaturePill(Icons.notifications_active, 'Event Alerts'),
                      _buildFeaturePill(Icons.photo_library, 'Gallery'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Bottom section
                  Material(
                    color: Colors.transparent,
                    child: Ink(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: InkWell(
                        onTap: () async {
                          final Uri emailLaunchUri = Uri(
                            scheme: 'mailto',
                            path: 'mygcet.official.53@gmail.com',
                            query: 'subject=Event Collaboration Inquiry',
                          );
                          // Try to launch directly, fallback to error snackbar if needed
                          try {
                            await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
                          } catch (e) {
                            debugPrint('Could not launch email: $e');
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.email_outlined, color: Colors.white70, size: 20),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Societies looking to collaborate for events can contact us at:\nmygcet.official.53@gmail.com',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
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
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Consumer<DataService>(
      builder: (context, dataService, child) {
        final upcomingQuizzes = dataService.quizzes
            .where((q) => q.status == 'upcoming')
            .take(3)
            .toList();

        if (upcomingQuizzes.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upcoming Quizzes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ...upcomingQuizzes.map((quiz) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: AppTheme.cardGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.quiz, color: Colors.white),
                      ),
                      title: Text(
                        quiz.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(quiz.subjectName),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Upcoming',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return DockNavBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        if (index == 0) {
          // Already on home, do nothing
          setState(() => _currentIndex = 0);
          return;
        }
        
        // Navigate to other screens and reset to home when returning
        setState(() => _currentIndex = index);
        
        String? route;
        switch (index) {
          case 1:
            route = AppRoutes.attendance;
            break;
          case 2:
            route = AppRoutes.materials;
            break;
          case 3:
            route = AppRoutes.profile;
            break;
        }
        
        if (route != null) {
          Navigator.pushNamed(context, route).then((_) {
            // Reset to Home when returning
            if (mounted) {
              setState(() => _currentIndex = 0);
            }
          });
        }
      },
      items: const [
        DockNavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          label: 'Home',
        ),
        DockNavItem(
          icon: Icons.check_circle_outline,
          activeIcon: Icons.check_circle_rounded,
          label: 'Attendance',
        ),
        DockNavItem(
          icon: Icons.folder_outlined,
          activeIcon: Icons.folder_rounded,
          label: 'Materials',
        ),
        DockNavItem(
          icon: Icons.person_outline,
          activeIcon: Icons.person_rounded,
          label: 'Profile',
        ),
      ],
    );
  }


  void _showExamPapersDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<DataService>(
        builder: (context, dataService, child) {
          final papers = dataService.examPapers;
          final isDark = Theme.of(context).brightness == Brightness.dark;
          
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B22) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'Exam Papers',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Access previous year question papers',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                ...papers.map((paper) => ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.description, color: Colors.blue),
                  ),
                  title: Text(
                    paper.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Open in Google Drive',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                  trailing: const Icon(Icons.open_in_new, size: 20),
                  onTap: () {
                    Navigator.pop(context);
                    _launchUrl(paper.url);
                  },
                )),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }
  Future<void> _checkMinVersion(String? minVersion) async {
    if (minVersion == null) return;
    
    // AppConstants.appVersion format: 1.0.0+2002
    try {
      final current = AppConstants.appVersion;
      if (current == minVersion) return; // Same version, OK
      
      int getBuildNumber(String v) {
         if (v.contains('+')) return int.tryParse(v.split('+')[1]) ?? 0;
         return 0; // If no build number, assume 0
      }
      
      final currentBuild = getBuildNumber(current);
      final minBuild = getBuildNumber(minVersion);
      
      if (currentBuild < minBuild) {
        // App is outdated!
        if (mounted) _showUpdateRequiredDialog();
      }
    } catch (e) {
      debugPrint('Error checking version: $e');
    }
  }

  void _showUpdateRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false, // Prevent back button
        child: AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [
            Icon(Icons.system_update_alt, color: Colors.amberAccent), 
            SizedBox(width: 12),
            Text('Update Required', style: TextStyle(color: Colors.white))
          ]),
          content: const Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               Text(
                'A critical update is available. You must update the app to improve the functionality and continue using it.',
                style: TextStyle(color: Colors.white70),
              ),
             ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Replace with your actual APK download URL
                   _launchUrl('https://tinyurl.com/mygcet-app');
                }, 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent),
                child: const Text('Update Now', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEasterEgg() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🥚 You found it! 🎉',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Crafted with ❤️ by ABDULLA KAPADIA\n\n'
              '"Code is not just my job, it\'s my passion."',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.code, color: Colors.purpleAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Version: ${AppConstants.appVersion}',
                    style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Nice! 👏', style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }
}

/// Glassmorphic announcement banner with pulse animation for unread items
class _GlassmorphicAnnouncementBanner extends StatefulWidget {
  final Announcement latestAnnouncement;
  final int totalCount;
  final int unreadCount;
  final VoidCallback onTap;

  const _GlassmorphicAnnouncementBanner({
    required this.latestAnnouncement,
    required this.totalCount,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  State<_GlassmorphicAnnouncementBanner> createState() => _GlassmorphicAnnouncementBannerState();
}

class _GlassmorphicAnnouncementBannerState extends State<_GlassmorphicAnnouncementBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Only animate if there are unread announcements
    if (widget.unreadCount > 0) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_GlassmorphicAnnouncementBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.unreadCount > 0 && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (widget.unreadCount == 0 && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.unreadCount > 0 ? _pulseAnimation.value : 1.0,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // Glassmorphic background
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  width: 1.5,
                  color: widget.unreadCount > 0
                      ? Color.lerp(
                          const Color(0xFF667eea).withOpacity(0.5),
                          const Color(0xFFa855f7).withOpacity(0.8),
                          _glowAnimation.value,
                        )!
                      : Colors.white.withOpacity(0.2),
                ),
                boxShadow: widget.unreadCount > 0
                    ? [
                        BoxShadow(
                          color: const Color(0xFF667eea).withOpacity(_glowAnimation.value * 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  // Icon container with gradient
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF667eea), Color(0xFFa855f7)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667eea).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.campaign_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Announcements',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (widget.unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFff416c), Color(0xFFff4b2b)],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${widget.unreadCount} new',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.latestAnnouncement.title.replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true), '').trim(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Arrow
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white.withOpacity(0.8),
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HolidayCard extends StatelessWidget {
  final String name;
  final String localName;
  final DateTime date;
  final int daysUntil;

  const _HolidayCard({
    required this.name,
    required this.localName,
    required this.date,
    required this.daysUntil,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.successGreen.withOpacity(0.9),
            AppTheme.successGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.successGreen.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  daysUntil == 0
                      ? 'Today!'
                      : daysUntil == 1
                          ? 'Tomorrow'
                          : 'In $daysUntil days',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.celebration,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('MMM d, yyyy').format(date),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



}
