import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/student_model.dart';
import '../models/attendance_model.dart';
import '../models/other_models.dart';

/// Service to communicate with the Python backend that uses Selenium.
/// This approach properly handles session management and cookies.
class BackendService {
  String? _sessionId;
  
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_sessionId != null) 'Authorization': 'Bearer $_sessionId',
  };

  /// Initialize session by fetching login page (establishes backend session)
  Future<BackendCaptchaResult> fetchCaptcha() async {
    try {
      final response = await http.get(
        Uri.parse(AppConstants.captchaEndpoint),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _sessionId = data['session_id'];
        
        Uint8List? captchaBytes;
        if (data['captcha_image'] != null && data['has_captcha'] == true) {
          // Decode base64 captcha image
          String base64Data = data['captcha_image'];
          if (base64Data.contains(',')) {
            base64Data = base64Data.split(',')[1];
          }
          captchaBytes = base64Decode(base64Data);
        }
        
        return BackendCaptchaResult(
          success: true,
          hasCaptcha: data['has_captcha'] ?? false,
          captchaImage: captchaBytes,
          sessionId: _sessionId,
        );
      }
      
      return BackendCaptchaResult(
        success: false,
        error: 'GMS Portal is currently unavailable. Please try again later.',
      );
    } catch (e) {
      print('BackendService.fetchCaptcha error: $e');
      return BackendCaptchaResult(
        success: false,
        error: 'GMS Portal is currently unavailable. Please try again later.',
      );
    }
  }

  /// Login using the Python backend
  Future<BackendLoginResult> login(String username, String password, String captcha) async {
    try {
      // First ensure we have a session
      if (_sessionId == null) {
        await fetchCaptcha();
      }
      
      print('BackendService: Logging in with session $_sessionId');
      
      final response = await http.post(
        Uri.parse(AppConstants.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'captcha': captcha,
          'session_id': _sessionId,
        }),
      ).timeout(const Duration(seconds: 60));

      print('BackendService: Login response status: ${response.statusCode}');
      print('BackendService: Login response body: ${response.body}');

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        _sessionId = data['session_id'];
        
        // Parse user data
        final userData = data['user'] ?? {};
        final student = Student(
          id: userData['id'] ?? '',
          name: userData['name'] ?? 'Student',
          rollNumber: userData['enrollment'] ?? username,
          enrollment: userData['enrollment'] ?? username,
          email: userData['email'] ?? '',
          phone: userData['phone'] ?? '',
          branch: userData['branch'] ?? '',
          semester: userData['semester'] ?? '',
          section: userData['section'] ?? '',
          batch: userData['batch'] ?? '',
          fatherName: userData['father_name'] ?? '',
          motherName: userData['mother_name'] ?? '',
          address: userData['address'] ?? '',
          registeredCourses: (userData['registered_courses'] as List?)
              ?.map((c) => RegisteredCourse(
                    code: c['code'] ?? '',
                    name: c['name'] ?? '',
                    type: c['type'] ?? '',
                  ))
              .toList() ?? [],
        );
        
        return BackendLoginResult(
          success: true,
          student: student,
          sessionId: _sessionId,
        );
      }
      
      return BackendLoginResult(
        success: false,
        error: data['message'] ?? 'Login failed',
      );
    } catch (e) {
      print('BackendService.login error: $e');
      return BackendLoginResult(
        success: false,
        error: 'GMS Portal is currently unavailable. Please try again later.',
      );
    }
  }

  /// Fetch attendance data
  Future<List<SubjectAttendance>> fetchAttendance() async {
    try {
      final response = await http.get(
        Uri.parse(AppConstants.attendanceEndpoint),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return (data['attendance'] as List?)
              ?.map((a) => SubjectAttendance(
                    subjectCode: a['subject_code'] ?? '',
                    subjectName: a['subject_name'] ?? '',
                    attendedClasses: a['attended_classes'] ?? 0,
                    totalClasses: a['total_classes'] ?? 0,
                    percentage: (a['percentage'] as num?)?.toDouble() ?? 0.0,
                  ))
              .toList() ?? [];
        }
      }
    } catch (e) {
      print('BackendService.fetchAttendance error: $e');
    }
    return [];
  }

  /// Fetch study materials
  Future<MaterialsResult> fetchMaterials({String? category, String? subject}) async {
    try {
      final Uri url;
      if (category != null && subject != null) {
        url = Uri.parse('${AppConstants.materialsEndpoint}/search');
        final response = await http.post(
          url,
          headers: _headers,
          body: jsonEncode({'category': category, 'subject': subject}),
        ).timeout(const Duration(seconds: 30));
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return MaterialsResult(
            materials: (data['materials'] as List?)
                ?.map((m) => StudyMaterial(
                      id: m['id'] ?? '',
                      title: m['title'] ?? '',
                      subjectCode: m['subject_code'] ?? '',
                      subjectName: m['subject_name'] ?? '',
                      type: m['type'],
                      uploadedBy: m['uploaded_by'],
                      uploadedAt: m['uploaded_at'],
                      url: m['download_url'],
                    ))
                .toList() ?? [],
            categories: [],
            subjects: [],
          );
        }
      } else {
        url = Uri.parse(AppConstants.materialsEndpoint);
        final response = await http.get(url, headers: _headers)
            .timeout(const Duration(seconds: 30));
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return MaterialsResult(
            materials: [],
            categories: (data['categories'] as List?)
                ?.map((c) => DropdownOption(value: c['value'], name: c['name']))
                .toList() ?? [],
            subjects: (data['subjects'] as List?)
                ?.map((s) => DropdownOption(value: s['value'], name: s['name']))
                .toList() ?? [],
          );
        }
      }
    } catch (e) {
      print('BackendService.fetchMaterials error: $e');
    }
    return MaterialsResult(materials: [], categories: [], subjects: []);
  }

  /// Fetch quiz data
  Future<List<Quiz>> fetchQuizzes() async {
    try {
      final response = await http.get(
        Uri.parse(AppConstants.quizEndpoint),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return (data['quizzes'] as List?)
              ?.map((q) => Quiz(
                    id: q['id'] ?? '',
                    title: q['title'] ?? '',
                    subjectCode: q['subject_code'] ?? '',
                    subjectName: q['subject_name'] ?? '',
                    score: int.tryParse(q['score']?.toString() ?? ''),
                    status: q['status'] ?? 'completed',
                  ))
              .toList() ?? [];
        }
      }
    } catch (e) {
      print('BackendService.fetchQuizzes error: $e');
    }
    return [];
  }

  /// Fetch library books
  Future<List<Book>> fetchLibraryBooks() async {
    try {
      final response = await http.get(
        Uri.parse(AppConstants.libraryEndpoint),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return (data['books'] as List?)
              ?.map((b) => Book(
                    id: b['id'] ?? '',
                    title: b['title'] ?? '',
                    author: b['author'] ?? '',
                    issueDate: b['issue_date'] ?? '',
                    dueDate: b['due_date'] ?? '',
                    status: b['status'] ?? 'issued',
                  ))
              .toList() ?? [];
        }
      }
    } catch (e) {
      print('BackendService.fetchLibraryBooks error: $e');
    }
    return [];
  }

  /// Fetch calendar events
  Future<List<CalendarEvent>> fetchCalendarEvents() async {
    try {
      final response = await http.get(
        Uri.parse(AppConstants.calendarEndpoint),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return (data['events'] as List?)
              ?.map((e) => CalendarEvent(
                    id: e['id'] ?? '',
                    title: e['title'] ?? '',
                    date: e['date'] ?? '',
                    description: e['description'] ?? '',
                    type: e['type'] ?? 'academic',
                  ))
              .toList() ?? [];
        }
      }
    } catch (e) {
      print('BackendService.fetchCalendarEvents error: $e');
    }
    return [];
  }

  /// Logout and cleanup backend session
  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('${AppConstants.baseUrl}/logout'),
        headers: _headers,
      );
    } catch (e) {
      // Ignore logout errors
    }
    _sessionId = null;
  }

  /// Set session from stored value
  void setSession(String sessionId) {
    _sessionId = sessionId;
  }

  /// Get current session ID
  String? get sessionId => _sessionId;

  /// Clear session
  void clearSession() {
    _sessionId = null;
  }
}

/// Result of captcha fetch
class BackendCaptchaResult {
  final bool success;
  final bool hasCaptcha;
  final Uint8List? captchaImage;
  final String? sessionId;
  final String? error;

  BackendCaptchaResult({
    required this.success,
    this.hasCaptcha = false,
    this.captchaImage,
    this.sessionId,
    this.error,
  });
}

/// Result of login attempt
class BackendLoginResult {
  final bool success;
  final Student? student;
  final String? sessionId;
  final String? error;

  BackendLoginResult({
    required this.success,
    this.student,
    this.sessionId,
    this.error,
  });
}

/// Dropdown option
class DropdownOption {
  final String value;
  final String name;

  DropdownOption({required this.value, required this.name});
}

/// Materials result
class MaterialsResult {
  final List<StudyMaterial> materials;
  final List<DropdownOption> categories;
  final List<DropdownOption> subjects;

  MaterialsResult({
    required this.materials,
    required this.categories,
    required this.subjects,
  });
}
