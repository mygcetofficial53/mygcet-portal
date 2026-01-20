import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'cache_service.dart';

/// Model class for Holiday
class Holiday {
  final String date;
  final String localName;
  final String name;
  final String countryCode;
  final bool fixed;
  final bool global;
  final List<String> types;

  Holiday({
    required this.date,
    required this.localName,
    required this.name,
    required this.countryCode,
    this.fixed = false,
    this.global = true,
    this.types = const [],
  });

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      date: json['date'] ?? '',
      localName: json['localName'] ?? '',
      name: json['name'] ?? '',
      countryCode: json['countryCode'] ?? 'IN',
      fixed: json['fixed'] ?? false,
      global: json['global'] ?? true,
      types: List<String>.from(json['types'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'localName': localName,
      'name': name,
      'countryCode': countryCode,
      'fixed': fixed,
      'global': global,
      'types': types,
    };
  }

  DateTime get dateTime => DateTime.parse(date);
  
  /// Get today's date with time stripped
  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
  
  /// Get this holiday's date with time stripped
  DateTime get _dateOnly {
    final dt = dateTime;
    return DateTime(dt.year, dt.month, dt.day);
  }
  
  bool get isToday => _dateOnly.isAtSameMomentAs(_today);
  
  bool get isUpcoming => _dateOnly.isAfter(_today) || isToday;
  
  int get daysUntil {
    final diff = _dateOnly.difference(_today).inDays;
    return diff < 0 ? 0 : diff;
  }
}

/// Service to fetch Indian public holidays
class HolidayService extends ChangeNotifier {
  final CacheService _cacheService = CacheService();
  
  List<Holiday> _holidays = [];
  bool _isLoading = false;
  String? _error;

  List<Holiday> get holidays => _holidays;
  List<Holiday> get upcomingHolidays => 
      _holidays.where((h) => h.isUpcoming).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch holidays from Nager.Date public API (free, no API key needed)
  Future<void> fetchHolidays({int? year}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final targetYear = year ?? DateTime.now().year;
    
    try {
      // Try to fetch from API
      final response = await http.get(
        Uri.parse('https://date.nager.at/api/v3/publicholidays/$targetYear/IN'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _holidays = data.map((e) => Holiday.fromJson(e)).toList();
        
        // Also fetch next year if we're near the end of the year
        if (DateTime.now().month >= 11) {
          await _fetchNextYearHolidays(targetYear + 1);
        }
        
        // Cache the holidays
        await _cacheService.cacheHolidays(
          _holidays.map((h) => h.toJson()).toList()
        );
      } else {
        throw Exception('Failed to fetch holidays');
      }
    } catch (e) {
      debugPrint('Error fetching holidays: $e');
      
      // Try to load from cache
      final cached = await _cacheService.getCachedHolidays();
      if (cached != null && cached.isNotEmpty) {
        _holidays = cached.map((e) => Holiday.fromJson(e)).toList();
        _error = 'Using cached data';
      } else {
        // Use fallback Indian holidays
        _holidays = _getFallbackHolidays();
        _error = 'Using offline holiday data';
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchNextYearHolidays(int year) async {
    try {
      final response = await http.get(
        Uri.parse('https://date.nager.at/api/v3/publicholidays/$year/IN'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _holidays.addAll(data.map((e) => Holiday.fromJson(e)));
      }
    } catch (e) {
      debugPrint('Error fetching next year holidays: $e');
    }
  }

  /// Fallback holidays for India 2026 (Official Bank Holidays)
  List<Holiday> _getFallbackHolidays() {
    return [
      // 2026 Official Bank Holidays
      Holiday(date: '2026-01-14', localName: 'मकर संक्रांति', name: 'Makar Sankranti', countryCode: 'IN', types: ['Public']),
      Holiday(date: '2026-01-26', localName: 'गणतंत्र दिवस', name: 'Republic Day', countryCode: 'IN', types: ['Public']),
      Holiday(date: '2026-02-15', localName: 'महा शिवरात्रि', name: 'Maha Shiv Ratri', countryCode: 'IN', types: ['Public']),
      Holiday(date: '2026-03-04', localName: 'धुलेटी', name: 'Dhuleti (2nd Day of Holi)', countryCode: 'IN', types: ['Public']),
      Holiday(date: '2026-03-21', localName: 'रमज़ान ईद', name: 'Ramzan Eid', countryCode: 'IN', types: ['Public']),
      Holiday(date: '2026-03-26', localName: 'श्री राम नवमी', name: 'Shree Ram Navmi', countryCode: 'IN', types: ['Public']),
      Holiday(date: '2026-03-31', localName: 'श्री महावीर जयंती', name: 'Shree Mahavir Jayanti', countryCode: 'IN', types: ['Public']),
      Holiday(date: '2026-04-03', localName: 'गुड फ्राइडे', name: 'Good Friday', countryCode: 'IN', types: ['Public']),
      Holiday(date: '2026-08-15', localName: 'स्वतंत्रता दिवस', name: 'Independence Day', countryCode: 'IN', types: ['Public']),
      Holiday(date: '2026-08-28', localName: 'रक्षा बंधन', name: 'Raksha Bandhan', countryCode: 'IN', types: ['Public']),
      Holiday(date: '2026-09-04', localName: 'श्री कृष्ण जन्माष्टमी', name: 'Shree Krishna Janmashtami', countryCode: 'IN', types: ['Public']),
      Holiday(date: '2026-10-02', localName: 'गांधी जयंती', name: 'Gandhi Jayanti', countryCode: 'IN', types: ['Public']),
      Holiday(date: '2026-10-20', localName: 'दशहरा', name: 'Dussehra', countryCode: 'IN', types: ['Public']),
      Holiday(date: '2026-10-31', localName: 'सरदार वल्लभभाई पटेल जयंती', name: 'Sardar Vallabhbhai Patel Jayanti', countryCode: 'IN', types: ['Public']),
      Holiday(date: '2026-11-08', localName: 'दीपावली', name: 'Diwali', countryCode: 'IN', types: ['Public']),
      Holiday(date: '2026-12-25', localName: 'क्रिसमस', name: 'Christmas Day', countryCode: 'IN', types: ['Public']),
      // 2027 Early Holidays
      Holiday(date: '2027-01-14', localName: 'मकर संक्रांति', name: 'Makar Sankranti', countryCode: 'IN', types: ['Public']),
      Holiday(date: '2027-01-26', localName: 'गणतंत्र दिवस', name: 'Republic Day', countryCode: 'IN', types: ['Public']),
    ];
  }

  /// Load holidays from cache
  Future<void> loadFromCache() async {
    final cached = await _cacheService.getCachedHolidays();
    if (cached != null && cached.isNotEmpty) {
      _holidays = cached.map((e) => Holiday.fromJson(e)).toList();
      notifyListeners();
    }
  }
}
