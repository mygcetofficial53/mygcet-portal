import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../models/announcement_model.dart';
import '../../widgets/animated_gradient_background.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch notifications when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final service = context.read<SupabaseService>();
      await service.fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Announcements',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          // TODO: Implement local read status for Supabase notifications if needed
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: AnimatedGradientBackground(),
          ),
          SafeArea(
            child: Consumer<SupabaseService>(
              builder: (context, supabaseService, child) {
                if (supabaseService.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (supabaseService.error != null) {
                  final isNetworkError = supabaseService.error!.contains('SocketException') || supabaseService.error!.contains('Failed host lookup');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isNetworkError ? Icons.wifi_off : Icons.error_outline, size: 64, color: Colors.white70),
                        const SizedBox(height: 16),
                        Text(
                          isNetworkError ? 'No Internet Connection' : 'Something went wrong',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            isNetworkError ? 'Please check your network settings.' : supabaseService.error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withOpacity(0.7)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => supabaseService.fetchNotifications(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryBlue,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final notifications = supabaseService.notifications;

                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'No Announcements',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You\'re all caught up!',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => supabaseService.fetchNotifications(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      final announcement = Announcement(
                        id: notif['id']?.toString() ?? '0',
                        title: notif['title'] ?? 'New Message',
                        message: notif['message'] ?? '',
                        type: AnnouncementType.values.firstWhere(
                          (e) => e.name == (notif['type'] ?? 'info'),
                          orElse: () => AnnouncementType.info,
                        ),
                        date: DateTime.tryParse(notif['created_at']?.toString() ?? '') ?? DateTime.now(),
                        isRead: false,
                      );
                      
                      return _AnnouncementListItem(
                        announcement: announcement,
                        onTap: () {}, // No explicit read action yet
                        onDismiss: () {
                            // TODO: Implement local dismiss
                        }, 
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementListItem extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _AnnouncementListItem({
    required this.announcement,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(announcement.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: _getGradient(),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _getPrimaryColor().withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getIcon(),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _getTypeLabel(),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            if (!announcement.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('MMM d, yyyy • h:mm a').format(announcement.date),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                announcement.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                announcement.message,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  LinearGradient _getGradient() {
    switch (announcement.type) {
      case AnnouncementType.info:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        );
      case AnnouncementType.success:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
        );
      case AnnouncementType.warning:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
        );
      case AnnouncementType.alert:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFff416c), Color(0xFFff4b2b)],
        );
      case AnnouncementType.event:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5CF6), Color(0xFFa855f7)],
        );
    }
  }

  Color _getPrimaryColor() {
    switch (announcement.type) {
      case AnnouncementType.info:
        return const Color(0xFF667eea);
      case AnnouncementType.success:
        return const Color(0xFF11998e);
      case AnnouncementType.warning:
        return const Color(0xFFf093fb);
      case AnnouncementType.alert:
        return const Color(0xFFff416c);
      case AnnouncementType.event:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData _getIcon() {
    switch (announcement.type) {
      case AnnouncementType.info:
        return Icons.info_outline;
      case AnnouncementType.success:
        return Icons.check_circle_outline;
      case AnnouncementType.warning:
        return Icons.warning_amber_outlined;
      case AnnouncementType.alert:
        return Icons.error_outline;
      case AnnouncementType.event:
        return Icons.event;
    }
  }

  String _getTypeLabel() {
    switch (announcement.type) {
      case AnnouncementType.info:
        return 'INFO';
      case AnnouncementType.success:
        return 'SUCCESS';
      case AnnouncementType.warning:
        return 'IMPORTANT';
      case AnnouncementType.alert:
        return 'ALERT';
      case AnnouncementType.event:
        return 'EVENT';
    }
  }
}
