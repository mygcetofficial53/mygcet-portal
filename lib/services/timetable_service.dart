import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/timetable_model.dart';
import '../models/student_model.dart'; // For converting RegisteredCourse to Subject

class TimetableService {
  static const String _timetableKey = 'timetable_data';
  static const String _subjectsKey = 'subjects_data';
  static const String _facultiesKey = 'faculties_data';

  // --- Timetable Operations ---

  Future<Timetable?> loadTimetable() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_timetableKey);
    if (jsonString == null) return null;
    try {
      final timetable = Timetable.fromJson(jsonDecode(jsonString));
      
      // Sort all slots chronologically on load
      for (final day in timetable.weekSchedule.keys) {
        timetable.weekSchedule[day]?.sort((a, b) => _compareTime(a.startTime, b.startTime));
      }
      
      return timetable;
    } catch (e) {
      debugPrint("Error loading timetable: $e");
      return null;
    }
  }

  Future<void> saveTimetable(Timetable timetable) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_timetableKey, jsonEncode(timetable.toJson()));
  }

  Future<void> addSlot(WeekDay day, TimeSlot slot) async {
    Timetable? current = await loadTimetable();
    current ??= Timetable(weekSchedule: {for (var d in WeekDay.values) d.name: []});
    
    // Ensure list exists
    if (!current.weekSchedule.containsKey(day.name)) {
      current.weekSchedule[day.name] = [];
    }
    
    current.weekSchedule[day.name]?.add(slot);
    
    // Sort immediately after adding
    current.weekSchedule[day.name]?.sort((a, b) => _compareTime(a.startTime, b.startTime));
    
    await saveTimetable(current);
  }

  Future<void> removeSlot(WeekDay day, TimeSlot slot) async {
    Timetable? current = await loadTimetable();
    if (current == null) return;
    
    // Better comparison since TimeSlot might not override equals
    current.weekSchedule[day.name]?.removeWhere((s) => 
      s.startTime == slot.startTime && s.endTime == slot.endTime && s.subject == slot.subject
    );
    
    await saveTimetable(current);
  }

  // --- Subject Operations ---

  Future<List<Subject>> loadSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_subjectsKey);
    if (jsonString == null) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list.map((e) => Subject.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error loading subjects: $e");
      return [];
    }
  }

  Future<void> saveSubjects(List<Subject> subjects) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subjectsKey, jsonEncode(subjects.map((e) => e.toJson()).toList()));
  }

  Future<void> addSubject(Subject subject) async {
    List<Subject> current = await loadSubjects();
    // Avoid duplicates
    if (!current.any((s) => s.code == subject.code)) {
      current.add(subject);
      await saveSubjects(current);
    }
  }

  Future<void> removeSubject(Subject subject) async {
    List<Subject> current = await loadSubjects();
    current.removeWhere((s) => s.code == subject.code);
    await saveSubjects(current);
  }

  Future<void> syncSubjectsFromRegisteredCourses(List<RegisteredCourse> courses) async {
    if (courses.isEmpty) return;
    final currentSubjects = await loadSubjects();
    bool changed = false;
    
    for (final course in courses) {
      if (!currentSubjects.any((s) => s.code == course.code)) {
        currentSubjects.add(Subject(name: course.name, code: course.code));
        changed = true;
      }
    }
    
    if (changed) {
      await saveSubjects(currentSubjects);
    }
  }

  // --- Faculty Operations ---

  Future<List<Faculty>> loadFaculties() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_facultiesKey);
    if (jsonString == null) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list.map((e) => Faculty.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error loading faculties: $e");
      return [];
    }
  }

  Future<void> saveFaculties(List<Faculty> faculties) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_facultiesKey, jsonEncode(faculties.map((e) => e.toJson()).toList()));
  }

  Future<void> addFaculty(Faculty faculty) async {
    List<Faculty> current = await loadFaculties();
    if (!current.any((f) => f.shortName == faculty.shortName)) {
      current.add(faculty);
      await saveFaculties(current);
    }
  }

  Future<void> removeFaculty(Faculty faculty) async {
    List<Faculty> current = await loadFaculties();
    current.removeWhere((f) => f.shortName == faculty.shortName);
    await saveFaculties(current);
  }

  // --- Utilities ---

  Future<TimeSlot?> getNextClass() async {
    final timetable = await loadTimetable();
    if (timetable == null) return null;

    final now = DateTime.now();
    final weekday = now.weekday; // 1 = Monday
    final currentDayName = _getDayName(weekday);
    final currentTimeStr = DateFormat("h:mm a").format(now);
    
    // Check remaining slots today
    if (timetable.weekSchedule.containsKey(currentDayName)) {
       final slots = timetable.weekSchedule[currentDayName]!;
       // Sort just in case
       slots.sort((a, b) => _compareTime(a.startTime, b.startTime));
       
       for (final slot in slots) {
         if (_compareTime(slot.startTime, currentTimeStr) > 0) {
           return slot;
         }
       }
    }
    
    // If no slots left today, check tomorrow
    final tomorrowDayName = _getDayName(weekday >= 7 ? 1 : weekday + 1);
    if (timetable.weekSchedule.containsKey(tomorrowDayName)) {
       final slots = timetable.weekSchedule[tomorrowDayName]!;
       slots.sort((a, b) => _compareTime(a.startTime, b.startTime));
       if (slots.isNotEmpty) return slots.first;
    }
    
    // If getting here, check start of next week (Monday)
    if (weekday >= 5) { // If Fri/Sat/Sun and no slots tomorrow/today
       final mondaySlots = timetable.weekSchedule['Monday'];
       if (mondaySlots != null && mondaySlots.isNotEmpty) {
         mondaySlots.sort((a, b) => _compareTime(a.startTime, b.startTime));
         return mondaySlots.first;
       }
    }
    
    return null;
  }

  Future<String> exportData() async {
    final timetable = await loadTimetable();
    final subjects = await loadSubjects();
    final faculties = await loadFaculties();
    
    final data = TimetableData(
      timetable: timetable,
      subjects: subjects,
      faculties: faculties,
    );
    
    return jsonEncode(data.toJson());
  }

  Future<bool> importData(String jsonString) async {
    try {
      final json = jsonDecode(jsonString);
      final data = TimetableData.fromJson(json);
      
      if (data.timetable != null) await saveTimetable(data.timetable!);
      if (data.subjects.isNotEmpty) await saveSubjects(data.subjects);
      if (data.faculties.isNotEmpty) await saveFaculties(data.faculties);
      
      return true;
    } catch (e) {
      debugPrint("Error importing data: $e");
      return false;
    }
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_timetableKey);
    await prefs.remove(_subjectsKey);
    await prefs.remove(_facultiesKey);
  }

  // --- Helpers ---

  int _compareTime(String time1, String time2) {
    final t1 = _parseTime(time1);
    final t2 = _parseTime(time2);
    if (t1 == null || t2 == null) return 0;
    
    // Debug logging for specific problematic case (only log occasionally or for specific times to avoid spam)
    if (time1.contains('9:05') || time1.contains('10:00')) {
       debugPrint('TimetableService: Comparing "$time1" (${t1.hour}:${t1.minute}) vs "$time2" (${t2.hour}:${t2.minute}) -> ${t1.compareTo(t2)}');
    }
    
    return t1.compareTo(t2);
  }

  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    if (weekday < 1 || weekday > 7) return 'Monday';
    return days[weekday - 1];
  }

  DateTime? _parseTime(String timeStr) {
    try {
      final now = DateTime.now();
      // Normalize: trim and uppercase to handle "am"/"pm"
      var cleanTime = timeStr.trim().toUpperCase();
      
      // Try 12-hour format first (e.g. "9:05 AM")
      if (cleanTime.contains('AM') || cleanTime.contains('PM')) {
         // Handle cases like "9:05AM" (no space) or "09:05 AM"
         // Insert space if missing between time and AM/PM
         if (!cleanTime.contains(' ')) {
           cleanTime = cleanTime.replaceAllMapped(RegExp(r'(\d+:\d+)([AP]M)'), (m) => '${m[1]} ${m[2]}');
         }
         
         // Use strict format parsing or try multiple
         try {
           final dt = DateFormat("h:mm a").parse(cleanTime);
           return DateTime(now.year, now.month, now.day, dt.hour, dt.minute);
         } catch (_) {
           // Fallback for "H:mm a" if h:mm fails (unlikely with DateFormat but safe)
           // If double digits header e.g. "09:05 AM"
           final dt = DateFormat("hh:mm a").parse(cleanTime);
           return DateTime(now.year, now.month, now.day, dt.hour, dt.minute);
         }
      }
      
      // Fallback to 24-hour format
      final parts = cleanTime.split(':');
      if (parts.length == 2) {
        // Remove non-digits just in case
        final hour = int.parse(parts[0].replaceAll(RegExp(r'[^0-9]'), ''));
        final minute = int.parse(parts[1].replaceAll(RegExp(r'[^0-9]'), ''));
        return DateTime(now.year, now.month, now.day, hour, minute);
      }
      
      return null;
    } catch (e) {
      debugPrint("Error parsing time '$timeStr': $e");
      return null;
    }
  }
}
