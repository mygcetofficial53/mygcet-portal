import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../services/data_service.dart';
import '../../services/holiday_service.dart';
import '../../models/other_models.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHolidays();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHolidays() async {
    await context.read<HolidayService>().fetchHolidays();
  }



  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final subTextColor = isDark ? Colors.white70 : AppTheme.textSecondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: isDark ? const Color(0xFF424242) : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: isDark ? Colors.white : AppTheme.primaryBlue,
              unselectedLabelColor: Colors.white,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(
                  height: 44,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.school, size: 18),
                      SizedBox(width: 6),
                      Text('Academic'),
                    ],
                  ),
                ),

                Tab(
                  height: 44,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.celebration, size: 18),
                      SizedBox(width: 6),
                      Text('Holidays'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // UG Academic Calendar Tab
          _buildUGAcademicCalendar(isDark, cardColor, textColor, subTextColor),

          // Holidays Tab
          Consumer<HolidayService>(
            builder: (context, holidayService, child) {
              if (holidayService.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return _buildHolidaysList(holidayService.holidays, isDark);
            },
          ),
        ],
      ),
    );
  }

  /// Build UG Academic Calendar with hardcoded dates
  Widget _buildUGAcademicCalendar(bool isDark, Color cardColor, Color textColor, Color subTextColor) {
    // UG Even Semester 2025-26 dates from academic calendar
    final ugEvents = [
      _AcademicEvent(
        title: 'Beginning of Even Semester',
        date: '22nd Dec 2025',
        semesters: 'Sem II, IV, VI, VIII',
        icon: Icons.play_arrow,
        color: AppTheme.successGreen,
      ),
      _AcademicEvent(
        title: 'Mid-term Exam',
        date: '23 - 28 Feb 2026',
        semesters: 'All Semesters',
        icon: Icons.edit_note,
        color: AppTheme.warningOrange,
      ),
      _AcademicEvent(
        title: 'Semester End',
        date: '4th Apr 2026',
        semesters: 'Sem II, IV, VI, VIII',
        icon: Icons.stop_circle,
        color: AppTheme.dangerRed,
      ),
      _AcademicEvent(
        title: 'Semester Duration',
        date: '15 Weeks',
        semesters: 'All Semesters',
        icon: Icons.schedule,
        color: AppTheme.primaryBlue,
      ),
      _AcademicEvent(
        title: 'University Theory & Practical Exams',
        date: '13th Apr 2026 onwards',
        semesters: 'All Semesters',
        icon: Icons.assignment,
        color: AppTheme.dangerRed,
      ),
      _AcademicEvent(
        title: 'Summer Vacation',
        date: '11th May - 20th June 2026',
        semesters: 'All Students',
        icon: Icons.beach_access,
        color: AppTheme.successGreen,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.primaryDark],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'UG Even Semester',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Academic Year 2025-26',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Events list
          ...ugEvents.map((event) => _buildAcademicEventCard(event, isDark, cardColor, textColor, subTextColor)),
        ],
      ),
    );
  }

  Widget _buildAcademicEventCard(_AcademicEvent event, bool isDark, Color cardColor, Color textColor, Color subTextColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : event.color.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: event.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(event.icon, color: event.color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.date,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: event.color,
                    ),
                  ),
                  Text(
                    event.semesters,
                    style: TextStyle(
                      fontSize: 12,
                      color: subTextColor,
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



  Widget _buildHolidaysList(List<Holiday> holidays, bool isDark) {
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    
    // Filter to show only upcoming and recent holidays
    final now = DateTime.now();
    final relevantHolidays = holidays.where((h) {
      final diff = h.dateTime.difference(now).inDays;
      return diff >= -30; // Show holidays from last 30 days onwards
    }).toList();

    relevantHolidays.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    // Group by month
    final grouped = <String, List<Holiday>>{};
    for (var holiday in relevantHolidays) {
      final monthKey = DateFormat('MMMM yyyy').format(holiday.dateTime);
      grouped.putIfAbsent(monthKey, () => []).add(holiday);
    }

    if (relevantHolidays.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.celebration_outlined,
              size: 80,
              color: isDark ? Colors.white24 : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No holidays found',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHolidays,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          final month = grouped.keys.elementAt(index);
          final monthHolidays = grouped[month]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      color: AppTheme.primaryBlue,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      month,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              ...monthHolidays.map((holiday) => _HolidayCard(holiday: holiday)),
            ],
          );
        },
      ),
    );
  }
}



class _HolidayCard extends StatelessWidget {
  final Holiday holiday;

  const _HolidayCard({required this.holiday});

  @override
  Widget build(BuildContext context) {
    final daysUntil = holiday.daysUntil;
    final isPast = daysUntil < 0;
    final color = AppTheme.successGreen;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: isPast
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF2C2C2C), const Color(0xFF1E1E1E)]
                    : [color.withOpacity(0.05), Colors.white],
              ),
        color: isPast ? (isDark ? Colors.black12 : Colors.grey.shade100) : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : color.withOpacity(isPast ? 0.05 : 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Date Box
            Container(
              width: 60,
              height: 70,
              decoration: BoxDecoration(
                color: isDark ? color.withOpacity(0.1) : color.withOpacity(isPast ? 0.1 : 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('d').format(holiday.dateTime),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isPast ? Colors.grey : color,
                    ),
                  ),
                  Text(
                    DateFormat('MMM').format(holiday.dateTime),
                    style: TextStyle(
                      fontSize: 13,
                      color: isPast ? Colors.grey : color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Holiday Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.celebration,
                        size: 18,
                        color: isPast ? Colors.grey : color,
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'HOLIDAY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isPast ? Colors.grey : color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    holiday.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isPast ? Colors.grey : textColor,
                    ),
                  ),
                ],
              ),
            ),
            if (!isPast)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  daysUntil == 0
                      ? 'Today! 🎉'
                      : daysUntil == 1
                          ? 'Tomorrow'
                          : 'In $daysUntil days',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Helper class for academic calendar events
class _AcademicEvent {
  final String title;
  final String date;
  final String semesters;
  final IconData icon;
  final Color color;

  _AcademicEvent({
    required this.title,
    required this.date,
    required this.semesters,
    required this.icon,
    required this.color,
  });
}
