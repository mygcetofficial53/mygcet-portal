import 'package:flutter/material.dart';
import '../../screens/login/login_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/attendance/attendance_screen.dart';
import '../../screens/materials/materials_screen.dart';
import '../../screens/calendar/calendar_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/results/results_screen.dart';
import '../../screens/timetable/timetable_screen.dart';
import '../../screens/idcard/id_card_screen.dart';
import '../../screens/announcements/announcements_screen.dart';
import '../../screens/admin/admin_notification_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String attendance = '/attendance';
  static const String materials = '/materials';
  static const String calendar = '/calendar';
  static const String profile = '/profile';
  static const String results = '/results';
  static const String timetable = '/timetable';
  static const String idcard = '/idcard';
  static const String announcements = '/announcements';
  static const String admin = '/admin';

  static Map<String, WidgetBuilder> get routes => {
        login: (context) => const LoginScreen(),
        dashboard: (context) => const DashboardScreen(),
        attendance: (context) => const AttendanceScreen(),
        materials: (context) => const MaterialsScreen(),
        calendar: (context) => const CalendarScreen(),
        profile: (context) => const ProfileScreen(),
        results: (context) => const ResultsScreen(),
        timetable: (context) => const TimetableScreen(),
        idcard: (context) => const IdCardScreen(),
        announcements: (context) => const AnnouncementsScreen(),
        admin: (context) => const AdminNotificationScreen(),
      };
}
