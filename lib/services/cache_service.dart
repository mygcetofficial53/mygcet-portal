import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for caching data locally for offline access
class CacheService {
  static const String _attendanceKey = 'cached_attendance';
  static const String _materialsKey = 'cached_materials';
  static const String _quizzesKey = 'cached_quizzes';
  static const String _eventsKey = 'cached_events';
  static const String _holidaysKey = 'cached_holidays';
  static const String _userProfileKey = 'cached_user_profile';
  static const String _lastUpdateKey = 'cache_last_update';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Cache attendance data
  Future<void> cacheAttendance(List<Map<String, dynamic>> data) async {
    try {
      final p = await prefs;
      await p.setString(_attendanceKey, jsonEncode(data));
      await _updateTimestamp();
    } catch (e) {
      debugPrint('Error caching attendance: $e');
    }
  }

  Future<List<Map<String, dynamic>>?> getCachedAttendance() async {
    try {
      final p = await prefs;
      final data = p.getString(_attendanceKey);
      if (data != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(data));
      }
    } catch (e) {
      debugPrint('Error getting cached attendance: $e');
    }
    return null;
  }

  // Cache materials data
  Future<void> cacheMaterials(List<Map<String, dynamic>> data) async {
    try {
      final p = await prefs;
      await p.setString(_materialsKey, jsonEncode(data));
      await _updateTimestamp();
    } catch (e) {
      debugPrint('Error caching materials: $e');
    }
  }

  Future<List<Map<String, dynamic>>?> getCachedMaterials() async {
    try {
      final p = await prefs;
      final data = p.getString(_materialsKey);
      if (data != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(data));
      }
    } catch (e) {
      debugPrint('Error getting cached materials: $e');
    }
    return null;
  }

  // Cache quizzes data
  Future<void> cacheQuizzes(List<Map<String, dynamic>> data) async {
    try {
      final p = await prefs;
      await p.setString(_quizzesKey, jsonEncode(data));
      await _updateTimestamp();
    } catch (e) {
      debugPrint('Error caching quizzes: $e');
    }
  }

  Future<List<Map<String, dynamic>>?> getCachedQuizzes() async {
    try {
      final p = await prefs;
      final data = p.getString(_quizzesKey);
      if (data != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(data));
      }
    } catch (e) {
      debugPrint('Error getting cached quizzes: $e');
    }
    return null;
  }

  // Cache events data
  Future<void> cacheEvents(List<Map<String, dynamic>> data) async {
    try {
      final p = await prefs;
      await p.setString(_eventsKey, jsonEncode(data));
      await _updateTimestamp();
    } catch (e) {
      debugPrint('Error caching events: $e');
    }
  }

  Future<List<Map<String, dynamic>>?> getCachedEvents() async {
    try {
      final p = await prefs;
      final data = p.getString(_eventsKey);
      if (data != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(data));
      }
    } catch (e) {
      debugPrint('Error getting cached events: $e');
    }
    return null;
  }

  // Cache holidays data
  Future<void> cacheHolidays(List<Map<String, dynamic>> data) async {
    try {
      final p = await prefs;
      await p.setString(_holidaysKey, jsonEncode(data));
      await _updateTimestamp();
    } catch (e) {
      debugPrint('Error caching holidays: $e');
    }
  }

  Future<List<Map<String, dynamic>>?> getCachedHolidays() async {
    try {
      final p = await prefs;
      final data = p.getString(_holidaysKey);
      if (data != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(data));
      }
    } catch (e) {
      debugPrint('Error getting cached holidays: $e');
    }
    return null;
  }

  // Cache user profile data
  Future<void> cacheUserProfile(Map<String, dynamic> data) async {
    try {
      final p = await prefs;
      await p.setString(_userProfileKey, jsonEncode(data));
      await _updateTimestamp();
    } catch (e) {
      debugPrint('Error caching user profile: $e');
    }
  }

  Future<Map<String, dynamic>?> getCachedUserProfile() async {
    try {
      final p = await prefs;
      final data = p.getString(_userProfileKey);
      if (data != null) {
        return Map<String, dynamic>.from(jsonDecode(data));
      }
    } catch (e) {
      debugPrint('Error getting cached user profile: $e');
    }
    return null;
  }

  // Update timestamp
  Future<void> _updateTimestamp() async {
    final p = await prefs;
    await p.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<DateTime?> getLastUpdateTime() async {
    try {
      final p = await prefs;
      final timestamp = p.getInt(_lastUpdateKey);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } catch (e) {
      debugPrint('Error getting last update time: $e');
    }
    return null;
  }

  // Check if cache is stale (older than 30 minutes)
  Future<bool> isCacheStale() async {
    final lastUpdate = await getLastUpdateTime();
    if (lastUpdate == null) return true;
    return DateTime.now().difference(lastUpdate).inMinutes > 30;
  }

  // Clear all cached data
  Future<void> clearCache() async {
    try {
      final p = await prefs;
      await p.remove(_attendanceKey);
      await p.remove(_materialsKey);
      await p.remove(_quizzesKey);
      await p.remove(_eventsKey);
      await p.remove(_holidaysKey);
      await p.remove(_userProfileKey);
      await p.remove(_lastUpdateKey);
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }
}
