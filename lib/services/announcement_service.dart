import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/announcement_model.dart';

/// Service for managing announcements
class AnnouncementService extends ChangeNotifier {
  List<Announcement> _announcements = [];
  bool _isLoading = false;

  List<Announcement> get announcements => _announcements;
  List<Announcement> get unreadAnnouncements => 
      _announcements.where((a) => !a.isRead).toList();
  bool get isLoading => _isLoading;
  bool get hasAnnouncements => _announcements.isNotEmpty;

  static const String _storageKey = 'announcements_data';
  static const String _readIdsKey = 'read_announcement_ids';

  AnnouncementService() {
    _loadAnnouncements();
  }

  /// Load announcements from storage or use demo data
  Future<void> _loadAnnouncements() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final readIds = prefs.getStringList(_readIdsKey) ?? [];
      
      // For now, use demo announcements
      // In future, this can fetch from backend
      _announcements = _getDemoAnnouncements().map((a) {
        return a.copyWith(isRead: readIds.contains(a.id));
      }).toList();

      // Sort by date, newest first
      _announcements.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      debugPrint('Error loading announcements: $e');
      _announcements = _getDemoAnnouncements();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Refresh announcements
  Future<void> refresh() async {
    await _loadAnnouncements();
  }

  /// Mark announcement as read
  Future<void> markAsRead(String id) async {
    final index = _announcements.indexWhere((a) => a.id == id);
    if (index != -1) {
      _announcements[index] = _announcements[index].copyWith(isRead: true);
      
      // Save to storage
      final prefs = await SharedPreferences.getInstance();
      final readIds = prefs.getStringList(_readIdsKey) ?? [];
      if (!readIds.contains(id)) {
        readIds.add(id);
        await prefs.setStringList(_readIdsKey, readIds);
      }
      
      notifyListeners();
    }
  }

  /// Dismiss/remove announcement from view
  Future<void> dismissAnnouncement(String id) async {
    _announcements.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final readIds = _announcements.map((a) => a.id).toList();
    await prefs.setStringList(_readIdsKey, readIds);
    
    _announcements = _announcements.map((a) => a.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  /// Demo announcements for initial display
  List<Announcement> _getDemoAnnouncements() {
    final now = DateTime.now();
    return [
      Announcement(
        id: 'ann_001',
        title: '🎓 Welcome to GCET Tracker!',
        message: 'Stay on top of your attendance, classes, and academic progress all in one place.',
        type: AnnouncementType.info,
        date: now.subtract(const Duration(hours: 2)),
      ),
      Announcement(
        id: 'ann_002',
        title: '⚠️ Attendance Alert',
        message: 'Keep your attendance above 75% to avoid detention. Check your subject-wise stats!',
        type: AnnouncementType.warning,
        date: now.subtract(const Duration(days: 1)),
      ),
      Announcement(
        id: 'ann_003',
        title: '🎉 New Features Coming Soon',
        message: 'Events registration and ID card features are under development. Stay tuned!',
        type: AnnouncementType.event,
        date: now.subtract(const Duration(days: 2)),
      ),
    ];
  }
}
