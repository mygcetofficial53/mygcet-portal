import 'package:flutter/foundation.dart';
import '../models/attendance_model.dart';
import '../models/other_models.dart';
import '../models/result_model.dart';
import '../models/student_model.dart';
import 'cache_service.dart';
import 'gms_scraper_service.dart';

/// Data service that fetches data directly from GMS portal via GmsScraperService.
/// No backend server required.
class DataService extends ChangeNotifier {
  final CacheService _cacheService = CacheService();
  GmsScraperService? _gmsService;
  bool _isDemoMode = false;
  
  bool _isLoading = false;
  String? _error;
  bool _isOffline = false;
  
  List<SubjectAttendance> _attendance = [];
  List<StudyMaterial> _materials = [];
  List<Quiz> _quizzes = [];
  List<Quiz> _quizSolutions = [];
  List<Book> _books = [];
  List<CalendarEvent> _events = [];
  List<DropdownOption> _materialCategories = [];
  List<DropdownOption> _materialSubjects = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOffline => _isOffline;
  bool get isDemoMode => _isDemoMode;
  List<SubjectAttendance> get attendance => _attendance;
  List<StudyMaterial> get materials => _materials;
  List<Quiz> get quizzes => _quizzes;
  List<Quiz> get quizSolutions => _quizSolutions;
  List<Book> get books => _books;
  List<CalendarEvent> get events => _events;
  List<DropdownOption> get materialCategories => _materialCategories;
  List<DropdownOption> get materialSubjects => _materialSubjects;
  
  List<MidSemResult> _midSem1 = [];
  List<MidSemResult> _midSem2 = [];
  List<ExamPaperLink> get examPapers => _gmsService?.getExamPaperLinks() ?? [];
  
  List<MidSemResult> get midSem1 => _midSem1;
  List<MidSemResult> get midSem2 => _midSem2;

  double get overallAttendance {
    if (_attendance.isEmpty) return 0.0;
    return _attendance.map((a) => a.percentage).reduce((a, b) => a + b) / _attendance.length;
  }

  int get upcomingQuizCount {
    return _quizzes.where((q) => q.status == 'upcoming').length;
  }

  int get overdueBookCount {
    return _books.where((b) => b.status == 'overdue').length;
  }

  /// Set the GMS scraper service (comes from AuthService)
  void setGmsService(GmsScraperService gmsService) {
    _gmsService = gmsService;
  }

  /// Enable demo mode and load demo data
  void setDemoMode(bool value) {
    _isDemoMode = value;
    notifyListeners();
  }

  /// Load demo data for all sections
  void loadDemoData() {
    _isDemoMode = true;
    _isLoading = true;
    notifyListeners();

    // Load demo attendance
    _attendance = SubjectAttendance.mockList();
    
    // Load demo materials
    _materials = DemoData.materials();
    
    // Load demo quizzes
    _quizzes = DemoData.quizzes();
    
    // Load demo books
    _books = DemoData.books();
    
    // Load demo events
    _events = DemoData.events();
    
    _isLoading = false;
    _isOffline = false;
    notifyListeners();
  }

  /// Search materials locally
  List<StudyMaterial> searchMaterials(String query) {
    if (query.isEmpty) return _materials;
    final lowerQuery = query.toLowerCase();
    return _materials.where((m) {
      return m.title.toLowerCase().contains(lowerQuery) ||
          m.subjectName.toLowerCase().contains(lowerQuery) ||
          m.subjectCode.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Search quizzes locally
  List<Quiz> searchQuizzes(String query) {
    if (query.isEmpty) return _quizzes;
    final lowerQuery = query.toLowerCase();
    return _quizzes.where((q) {
      return q.title.toLowerCase().contains(lowerQuery) ||
          q.subjectName.toLowerCase().contains(lowerQuery) ||
          q.subjectCode.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Fetch attendance data directly from GMS
  /// If attendance data is empty but student has registered courses, use those as fallback
  Future<void> fetchAttendance({Student? student}) async {
    if (_gmsService == null) {
      _error = 'Not logged in';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    // Preserve existing data before fetch attempt
    final previousAttendance = List<SubjectAttendance>.from(_attendance);

    try {
      final attendanceList = await _gmsService!.scrapeAttendance();
      
      if (attendanceList.isNotEmpty) {
        _attendance = attendanceList;
        _isOffline = false;
        
        // Cache the data
        await _cacheService.cacheAttendance(
          attendanceList.map((a) => a.toJson()).toList()
        );
      } else {
        // Attendance page returned empty (likely session expired) - try fallbacks
        debugPrint('DataService: No attendance data from GMS, trying fallbacks');
        
        // PRIORITY 1: Try cache FIRST (preserves actual attendance percentages)
        final cached = await _cacheService.getCachedAttendance();
        if (cached != null && cached.isNotEmpty) {
          _attendance = cached.map((e) => SubjectAttendance.fromJson(e)).toList();
          _isOffline = true;
          debugPrint('DataService: Loaded ${_attendance.length} subjects from cache');
        }
        // PRIORITY 2: Use registered courses (shows subjects but with 0% attendance)
        else if (student != null && student.registeredCourses.isNotEmpty) {
          debugPrint('DataService: Using ${student.registeredCourses.length} registered courses as fallback');
          _attendance = student.registeredCourses.map((course) => SubjectAttendance(
            subjectCode: course.code,
            subjectName: course.name,
            totalClasses: 0,
            attendedClasses: 0,
            percentage: 0.0,
          )).toList();
          _isOffline = true;
          // Don't cache fallback data - it has 0% attendance
        }
        // PRIORITY 3: Preserve previous data if we had any
        else if (previousAttendance.isNotEmpty) {
          _attendance = previousAttendance;
          _isOffline = true;
          debugPrint('DataService: Preserved ${_attendance.length} previous attendance records');
        }
      }
    } catch (e) {
      debugPrint('Error fetching attendance: $e');
      _error = 'Failed to fetch attendance';
      
      // PRIORITY 1: Try cache FIRST
      final cached = await _cacheService.getCachedAttendance();
      if (cached != null && cached.isNotEmpty) {
        _attendance = cached.map((e) => SubjectAttendance.fromJson(e)).toList();
        _isOffline = true;
        debugPrint('DataService: Loaded ${_attendance.length} subjects from cache on error');
      }
      // PRIORITY 2: Use registered courses
      else if (student != null && student.registeredCourses.isNotEmpty) {
        _attendance = student.registeredCourses.map((course) => SubjectAttendance(
          subjectCode: course.code,
          subjectName: course.name,
          totalClasses: 0,
          attendedClasses: 0,
          percentage: 0.0,
        )).toList();
        _isOffline = true;
      }
      // PRIORITY 3: Preserve previous data
      else if (previousAttendance.isNotEmpty) {
        _attendance = previousAttendance;
        _isOffline = true;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Fetch materials categories and subjects from GMS
  Future<void> fetchMaterials({Student? student}) async {
    if (_gmsService == null) return;

    try {
      final result = await _gmsService!.scrapeMaterials();
      
      _materialCategories = result.categories;
      
      // PRIORITY: Always populate subjects from Student Registered Courses if available
      // This ensures the list is "dynamic per student" and accurate to their current semester
      if (student != null && student.registeredCourses.isNotEmpty) {
         final uniqueCodes = <String>{};
         _materialSubjects = [];
         debugPrint('DataService: Using registered courses for material subjects (Priority)');
         for (final c in student.registeredCourses) {
           if (!uniqueCodes.contains(c.code)) {
             uniqueCodes.add(c.code);
             _materialSubjects.add(DropdownOption(value: c.code, name: '${c.code} - ${c.name}'));
           }
         }
      } else {
        // Fallback to scraped subjects if we don't have student data (or if it's empty)
        _materialSubjects = result.subjects;
        
        // Secondary Fallback: Use attendance data
        if (_materialSubjects.isEmpty && _attendance.isNotEmpty) {
           final uniqueCodes = <String>{};
           debugPrint('DataService: Using attendance list for material subjects fallback');
           for (final a in _attendance) {
             if (!uniqueCodes.contains(a.subjectCode)) {
               uniqueCodes.add(a.subjectCode);
               _materialSubjects.add(DropdownOption(value: a.subjectCode, name: '${a.subjectCode} - ${a.subjectName}'));
             }
           }
        }
      }
      
      _materials = result.materials;
      // _isOffline = false; // Removed to prevent false online status
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching materials: $e');
      
      // Try to load from cache
      final cached = await _cacheService.getCachedMaterials();
      if (cached != null && cached.isNotEmpty) {
        _materials = cached.map((e) => StudyMaterial.fromJson(e)).toList();
        _isOffline = true;
      }
      
      // Still allow subject population on error
      if (student != null && student.registeredCourses.isNotEmpty) {
         final uniqueCodes = <String>{};
         _materialSubjects = [];
         for (final c in student.registeredCourses) {
           if (!uniqueCodes.contains(c.code)) {
             uniqueCodes.add(c.code);
             _materialSubjects.add(DropdownOption(value: c.code, name: '${c.code} - ${c.name}'));
           }
         }
      }
      
      notifyListeners();
    }
  }

  /// Search materials by category and subject
  Future<void> searchMaterialsByFilter(String? category, String subject) async {
    if (_gmsService == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _gmsService!.scrapeMaterials(
        category: category,
        subject: subject,
      );
      
      _materials = result.materials;
      
      // Cache the data
      if (_materials.isNotEmpty) {
        await _cacheService.cacheMaterials(
          _materials.map((m) => m.toJson()).toList()
        );
      }
    } catch (e) {
      debugPrint('Error searching materials: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Search materials by course code or partial course name (text search)
  Future<void> searchMaterialsByText(String searchQuery, {String? category}) async {
    if (_gmsService == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _gmsService!.scrapeMaterials(
        searchQuery: searchQuery,
        category: category,
      );
      
      _materials = result.materials;
      
      // Cache the data
      if (_materials.isNotEmpty) {
        await _cacheService.cacheMaterials(
          _materials.map((m) => m.toJson()).toList()
        );
      }
    } catch (e) {
      debugPrint('Error searching materials by text: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Fetch quizzes from GMS
  Future<void> fetchQuizzes() async {
    if (_gmsService == null) return;

    try {
      final quizList = await _gmsService!.scrapeQuizzes();
      
      if (quizList.isNotEmpty) {
        _quizzes = quizList;
        // _isOffline = false; // Removed
        
        // Cache the data
        await _cacheService.cacheQuizzes(
          quizList.map((q) => q.toJson()).toList()
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching quizzes: $e');
      
      // Try to load from cache
      final cached = await _cacheService.getCachedQuizzes();
      if (cached != null && cached.isNotEmpty) {
        _quizzes = cached.map((e) => Quiz.fromJson(e)).toList();
        _isOffline = true;
      }
      notifyListeners();
    }
  }

  /// Fetch library books from GMS
  Future<void> fetchBooks() async {
    if (_gmsService == null) return;

    try {
      final bookList = await _gmsService!.scrapeLibraryBooks();
      
      if (bookList.isNotEmpty) {
        _books = bookList;
        _books = bookList;
        // _isOffline = false; // Removed
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching books: $e');
    }
  }

  /// Fetch calendar events from GMS
  Future<void> fetchEvents() async {
    if (_gmsService == null) return;

    try {
      final eventList = await _gmsService!.scrapeCalendarEvents();
      
      if (eventList.isNotEmpty) {
        _events = eventList;
        _events = eventList;
        // _isOffline = false; // Removed
        
        await _cacheService.cacheEvents(
          eventList.map((e) => e.toJson()).toList()
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching events: $e');
      
      final cached = await _cacheService.getCachedEvents();
      if (cached != null && cached.isNotEmpty) {
        _events = cached.map((e) => CalendarEvent.fromJson(e)).toList();
        _isOffline = true;
      }
      notifyListeners();
    }
  }

  /// Load cached data (for initial offline load)
  Future<void> loadCachedData() async {
    final cachedAttendance = await _cacheService.getCachedAttendance();
    if (cachedAttendance != null && cachedAttendance.isNotEmpty) {
      _attendance = cachedAttendance.map((e) => SubjectAttendance.fromJson(e)).toList();
    }

    final cachedMaterials = await _cacheService.getCachedMaterials();
    if (cachedMaterials != null && cachedMaterials.isNotEmpty) {
      _materials = cachedMaterials.map((e) => StudyMaterial.fromJson(e)).toList();
    }

    final cachedQuizzes = await _cacheService.getCachedQuizzes();
    if (cachedQuizzes != null && cachedQuizzes.isNotEmpty) {
      _quizzes = cachedQuizzes.map((e) => Quiz.fromJson(e)).toList();
    }

    final cachedEvents = await _cacheService.getCachedEvents();
    if (cachedEvents != null && cachedEvents.isNotEmpty) {
      _events = cachedEvents.map((e) => CalendarEvent.fromJson(e)).toList();
    }

    // Don't set offline here - let fetchAllData determine that after trying fresh fetch
    if (_attendance.isNotEmpty || _materials.isNotEmpty) {
      notifyListeners();
    }
  }

  /// Fetch all data from GMS
  /// Pass student to enable fallback to registered courses if attendance is empty
  Future<void> fetchAllData({Student? student}) async {
    _isLoading = true;
    notifyListeners();

    // First load cached data for instant display
    await loadCachedData();

    // Then fetch fresh data from GMS
    await Future.wait([
      fetchAttendance(student: student),
      fetchMaterials(student: student),
      fetchQuizzes(),
      fetchBooks(),
      fetchEvents(),
    ]);

    // After fetching, if we successfully got fresh data, ensure offline is false
    // _isOffline will only be true if ALL fetches fell back to cache
    // If any fetch succeeded (set _isOffline = false), we're online
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMidSemResults() async {
     if (_gmsService == null) return;
     try {
       _midSem1 = await _gmsService!.scrapeMidSemMarks(1);
       _midSem2 = await _gmsService!.scrapeMidSemMarks(2);
       notifyListeners();
     } catch (e) {
       debugPrint('Error fetching mid sem results: $e');
     }
  }

  Future<void> fetchQuizSolutions() async {
    if (_gmsService == null) return;
    try {
      final solutions = await _gmsService!.scrapeQuizSolutions();
      _quizSolutions = solutions;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching quiz solutions: $e');
    }
  }

  /// Clear all data
  void clearData() {
    _attendance = [];
    _materials = [];
    _quizzes = [];
    _books = [];
    _events = [];
    _materialCategories = [];
    _materialSubjects = [];
    _isOffline = false;
    _isDemoMode = false;
    _error = null;
    _gmsService = null;
    _cacheService.clearCache();
    notifyListeners();
  }
}
