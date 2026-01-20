import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/timetable_model.dart';

/// Service to handle all local notifications including class reminders
/// and attendance alerts
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  static const String _remindersEnabledKey = 'class_reminders_enabled';
  static const String _lowAttendanceAlertKey = 'low_attendance_alert_dismissed_date';
  static const int _reminderMinutesBefore = 15;

  bool _initialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz_data.initializeTimeZones();
    
    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap - can navigate to timetable
    // For now, just log it
    print('Notification tapped: ${response.payload}');
  }

  /// Request notification permissions (call on first app launch or when enabling)
  Future<bool> requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true; // iOS handles permissions differently
  }

  /// Check if class reminders are enabled
  Future<bool> areRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_remindersEnabledKey) ?? false;
  }

  /// Enable or disable class reminders
  Future<void> setRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_remindersEnabledKey, enabled);
    
    if (!enabled) {
      await cancelAllReminders();
    }
  }

  /// Schedule a single class reminder
  Future<void> scheduleClassReminder({
    required int id,
    required String subject,
    required String time,
    required String room,
    required DateTime scheduledTime,
  }) async {
    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    // Don't schedule if time has already passed
    if (tzScheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      'class_reminders',
      'Class Reminders',
      channelDescription: 'Notifications for upcoming classes',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF1565C0),
      styleInformation: BigTextStyleInformation(
        'Your $subject class starts in $_reminderMinutesBefore minutes${room.isNotEmpty ? ' in $room' : ''}',
        contentTitle: '📚 Upcoming Class: $subject',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      '📚 Upcoming Class',
      '$subject at $time${room.isNotEmpty ? ' in $room' : ''}',
      tzScheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'class_reminder',
    );
  }

  /// Schedule all class reminders for the week based on timetable
  Future<void> scheduleWeeklyReminders(Timetable timetable) async {
    // First cancel all existing reminders
    await cancelAllReminders();

    final enabled = await areRemindersEnabled();
    if (!enabled) return;

    final now = DateTime.now();
    int notificationId = 1000; // Start with high ID to avoid conflicts

    // Get current week's Monday
    final monday = now.subtract(Duration(days: now.weekday - 1));

    // Schedule for each day
    for (int dayIndex = 0; dayIndex < 6; dayIndex++) {
      final dayName = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'][dayIndex];
      final slots = timetable.weekSchedule[dayName] ?? [];
      
      for (final slot in slots) {
        // Parse the start time
        final timeParts = slot.startTime.split(':');
        if (timeParts.length != 2) continue;

        final hour = int.tryParse(timeParts[0]) ?? 0;
        final minute = int.tryParse(timeParts[1]) ?? 0;

        // Calculate the date for this class
        final classDate = monday.add(Duration(days: dayIndex));
        final classDateTime = DateTime(
          classDate.year,
          classDate.month,
          classDate.day,
          hour,
          minute,
        );

        // Schedule reminder 15 minutes before
        final reminderTime = classDateTime.subtract(
          Duration(minutes: _reminderMinutesBefore),
        );

        // Only schedule if it's in the future
        if (reminderTime.isAfter(now)) {
          await scheduleClassReminder(
            id: notificationId++,
            subject: slot.subject,
            time: slot.startTime,
            room: slot.room,
            scheduledTime: reminderTime,
          );
        }
      }
    }
  }

  /// Cancel all scheduled reminders
  Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }

  /// Show immediate notification for low attendance
  Future<void> showLowAttendanceNotification({
    required int subjectCount,
    required String worstSubject,
    required double worstPercentage,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'attendance_alerts',
      'Attendance Alerts',
      channelDescription: 'Alerts for low attendance',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFD32F2F),
      styleInformation: BigTextStyleInformation(
        '$subjectCount subject(s) below 75%. $worstSubject is at ${worstPercentage.toStringAsFixed(1)}%. Attend more classes to improve!',
        contentTitle: '⚠️ Attendance Warning',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999, // Fixed ID for attendance alerts
      '⚠️ Low Attendance Warning',
      '$subjectCount subject(s) need attention',
      details,
      payload: 'attendance_alert',
    );
  }

  /// Check if low attendance alert was already shown today
  Future<bool> wasLowAttendanceAlertShownToday() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedDate = prefs.getString(_lowAttendanceAlertKey);
    if (dismissedDate == null) return false;
    
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    return dismissedDate == todayStr;
  }

  /// Mark low attendance alert as dismissed for today
  Future<void> dismissLowAttendanceAlertForToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    await prefs.setString(_lowAttendanceAlertKey, todayStr);
  }
}

