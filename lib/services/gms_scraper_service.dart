import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:flutter/foundation.dart'; // For kIsWeb
import '../models/student_model.dart';
import '../models/attendance_model.dart';
import '../models/other_models.dart';
import '../models/result_model.dart';

/// Service to directly communicate with GMS portal via HTTP requests.
/// Uses Dio with proper cookie management for session handling.
class GmsScraperService {
  // GMS Portal URLs
  // GMS Portal URLs
  // GMS Portal URLs
  static String? _webSessionId;

  static String get _baseUrl {
    String targetUrl = 'http://202.129.240.148:8080/GIS';
    
    // Manual URL rewriting for session persistence on Web
    if (kIsWeb && _webSessionId != null) {
      targetUrl += ';jsessionid=$_webSessionId';
    }
    
    if (kIsWeb) {
      return 'https://corsproxy.io/?$targetUrl';
    }
    return targetUrl;
  }
      
  static String get _loginUrl => '$_baseUrl/StudentLogin.jsp';
  static String get _welcomeUrl => '$_baseUrl/Student/WelCome.jsp';
  static String get _attendanceUrl => '$_baseUrl/Student/ViewMyAttendance.jsp';
  static String get _materialsUrl => '$_baseUrl/Student/ViewUploadMaterialNew.jsp';
  static String get _quizUrl => '$_baseUrl/Student/Quiz_Result.jsp';
  static String get _libraryUrl => '$_baseUrl/Library/Library_Book_Issued.jsp';
  static String get _calendarUrl => '$_baseUrl/Student/Academic_Calender.jsp';
  static String get _profileUrl => '$_baseUrl/Student/Profile/ViewProfile.jsp';

  // Dio client with cookie jar for proper session management
  late Dio _dio;
  final CookieJar _cookieJar = CookieJar();
  
  // Stored credentials for re-authentication
  String? _username;
  String? _password;

  GmsScraperService() {
    _dio = Dio(BaseOptions(
      // Disabled withCredentials on web to avoid CORS errors with public proxy
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      followRedirects: true,
      maxRedirects: 5,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.5',
      },
    ));
    
    // Add cookie manager for proper session handling
    if (!kIsWeb) {
      _dio.interceptors.add(CookieManager(_cookieJar));
    }
  }

  /// Convert Roman numerals to digits (I-X)
  /// Handles: I=1, II=2, III=3, IV=4, V=5, VI=6, VII=7, VIII=8, IX=9, X=10
  static String _romanToDigit(String roman) {
    final romanMap = {
      'I': '1', 'II': '2', 'III': '3', 'IV': '4', 'V': '5',
      'VI': '6', 'VII': '7', 'VIII': '8', 'IX': '9', 'X': '10',
    };
    
    // Clean the input and convert to uppercase
    final cleaned = roman.trim().toUpperCase();
    
    // If it's already a number, return as-is
    if (RegExp(r'^\d+$').hasMatch(cleaned)) {
      return cleaned;
    }
    
    // Look up in map
    if (romanMap.containsKey(cleaned)) {
      return romanMap[cleaned]!;
    }
    
    // Return original if not found
    return roman;
  }

  /// Initialize session by fetching login page
  Future<GmsCaptchaResult> fetchCaptcha() async {
    try {
      print('GmsScraperService: Fetching login page to establish session...');
      
      // Get the login page to establish session cookies
      final response = await _dio.get(_loginUrl);
      
      print('GmsScraperService: Login page status: ${response.statusCode}');
      
      // Get cookies for this session
      final cookies = await _cookieJar.loadForRequest(Uri.parse(_loginUrl));
      print('GmsScraperService: Got ${cookies.length} cookies');

      // GMS portal does not have captcha
      return GmsCaptchaResult(
        success: true,
        hasCaptcha: false,
        captchaImage: null,
        sessionCookie: cookies.map((c) => '${c.name}=${c.value}').join('; '),
      );
    } catch (e) {
      print('GmsScraperService: Error fetching login page: $e');
      return GmsCaptchaResult(
        success: false,
        error: 'GMS Portal is currently unavailable. Please try again later.',
      );
    }
  }

  /// Login to GMS portal
  Future<GmsLoginResult> login(String username, String password, String captcha) async {
    try {
      _username = username;
      _password = password;

      print('GmsScraperService: Starting login for $username');

      // First, fetch login page to get session cookie
      await _dio.get(_loginUrl);
      
      print('GmsScraperService: Got initial session, now submitting login form...');

      // IMPORTANT: Form submits to LoginCheckStudent.do, not the login page itself!
      // Form fields: login_id, pass, login_type
      // CRITICAL: Password must be MD5 hashed before sending!
      final loginActionUrl = '$_baseUrl/LoginCheckStudent.do';
      
      // Hash password with MD5 (GMS JavaScript does this before submission)
      final passwordMd5 = md5.convert(utf8.encode(password)).toString();
      print('GmsScraperService: Password hashed with MD5');
      
      final response = await _dio.post(
        loginActionUrl,
        data: {
          'login_id': username,
          'pass': passwordMd5,  // MD5 hashed password!
          'login_type': 'Normal',
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      print('GmsScraperService: Login response status: ${response.statusCode}');
      print('GmsScraperService: Login response URL: ${response.realUri}');
      
      // Manual Session Capture for Web (URL Rewriting)
      if (kIsWeb) {
         final uriString = response.realUri.toString();
         final match = RegExp(r';jsessionid=([^?&/]+)', caseSensitive: false).firstMatch(uriString);
         if (match != null) {
           _webSessionId = match.group(1);
           print('GmsScraperService: Captured JSESSIONID from URL: $_webSessionId');
         }
      }

      final responseBody = response.data.toString().toLowerCase();
      
      // Print first 500 chars for debugging
      final bodyPreview = response.data.toString();
      print('GmsScraperService: Response preview: ${bodyPreview.substring(0, bodyPreview.length > 300 ? 300 : bodyPreview.length)}');
      
      // Check for error messages in login response
      if (responseBody.contains('invalid') || 
          responseBody.contains('wrong password') || 
          responseBody.contains('incorrect')) {
        return GmsLoginResult(
          success: false,
          error: 'Invalid enrollment number or password.',
        );
      }

      // Try to access Welcome page to verify login
      print('GmsScraperService: Fetching welcome page to verify login...');
      final welcomeResponse = await _dio.get(_welcomeUrl);
      
      print('GmsScraperService: Welcome page status: ${welcomeResponse.statusCode}');
      print('GmsScraperService: Welcome page URL: ${welcomeResponse.realUri}');
      
      final welcomeBody = welcomeResponse.data.toString().toLowerCase();
      final welcomeBodyOriginal = welcomeResponse.data.toString();
      
      // Print welcome page preview
      print('GmsScraperService: Welcome preview: ${welcomeBodyOriginal.substring(0, welcomeBodyOriginal.length > 300 ? 300 : welcomeBodyOriginal.length)}');
      
      // Check if we got redirected back to login page
      final isOnLoginPage = welcomeBody.contains('login_id') || 
          welcomeBody.contains('name="pass"') ||
          welcomeBody.contains('studentlogin.jsp');
      
      print('GmsScraperService: Is on login page: $isOnLoginPage');
      
      if (isOnLoginPage) {
        return GmsLoginResult(
          success: false,
          error: 'Login failed. Please check your enrollment number and password.',
        );
      }
      
      // Check for positive login indicators
      final hasLogout = welcomeBody.contains('logout');
      final hasWelcome = welcomeBody.contains('welcome');
      final hasStudent = welcomeBody.contains('student');
      final hasCourse = welcomeBody.contains('course');
      
      print('GmsScraperService: Login indicators - logout:$hasLogout, welcome:$hasWelcome, student:$hasStudent, course:$hasCourse');
      
      final isLoggedIn = hasLogout || hasWelcome || hasStudent || hasCourse;

      if (isLoggedIn) {
        // Scrape user profile
        final student = await _scrapeProfile(username);
        
        String cookieString;
        if (kIsWeb && _webSessionId != null) {
           // For Web, construct cookie string manually since we can't access browser cookies
           cookieString = 'JSESSIONID=$_webSessionId';
        } else {
           final cookies = await _cookieJar.loadForRequest(Uri.parse(_loginUrl));
           cookieString = cookies.map((c) => '${c.name}=${c.value}').join('; ');
        }
        
        return GmsLoginResult(
          success: true,
          student: student,
          sessionCookie: cookieString,
        );
      }

      return GmsLoginResult(
        success: false,
        error: 'Login failed. Please check your credentials.',
      );

    } catch (e) {
      print('GmsScraperService: Login error: $e');
      return GmsLoginResult(
        success: false,
        error: 'GMS Portal is currently unavailable. Please try again later.',
      );
    }
  }

  /// Scrape student profile from GMS
  Future<Student> _scrapeProfile(String enrollment) async {
    String name = '';
    String email = '';
    String phone = '';
    String branch = '';
    String semester = '';
    String section = '';
    String batch = '';
    String fatherName = '';
    String motherName = '';
    String address = '';
    List<RegisteredCourse> courses = [];

    try {
      // Get welcome page - this has all the profile info
      final welcomeResponse = await _dio.get(_welcomeUrl);
      final welcomeDoc = html_parser.parse(welcomeResponse.data.toString());
      final bodyText = welcomeDoc.body?.text ?? '';

      print('GmsScraperService: Scraping profile from welcome page...');

      // The GMS welcome page has profile data in tables with format:
      // Row: Label: | Value
      // e.g., "Enrollment No:" | "12502080503001"
      //       "Name:" | "KAPADIA ABDULLA AKIL"
      //       "Registered Email :" | "email@example.com"
      
      final tables = welcomeDoc.querySelectorAll('table');
      for (final table in tables) {
        final rows = table.querySelectorAll('tr');
        for (final row in rows) {
          final cols = row.querySelectorAll('td');
          if (cols.length >= 2) {
            final label = cols[0].text.trim().toLowerCase();
            final value = cols[1].text.trim();
            
            // Check for various profile fields
            if (label.contains('name') && !label.contains('father') && !label.contains('mother') && !label.contains('course')) {
              if (name.isEmpty && value.isNotEmpty && value.length > 2) {
                name = value;
                print('GmsScraperService: Found name: $name');
              }
            } else if (label.contains('email') || label.contains('e-mail')) {
              if (email.isEmpty && value.contains('@')) {
                email = value;
                print('GmsScraperService: Found email: $email');
              }
            } else if (label.contains('phone') || label.contains('mobile') || label.contains('contact')) {
              if (phone.isEmpty && value.isNotEmpty) {
                phone = value;
              }
            } else if (label.contains('branch') || label.contains('department') || label.contains('dept')) {
              if (branch.isEmpty) branch = value;
            } else if (label.contains('semester') || label.contains('sem ') || label.contains('current sem')) {
              if (semester.isEmpty) semester = _romanToDigit(value);
            } else if (label.contains('section') || label.contains('class')) {
              if (section.isEmpty) section = value;
              // Try to infer semester from Class string (e.g. "BE-IT-5" or "IT-V")
              if (semester.isEmpty && value.isNotEmpty) {
                 final lastChar = value.trim().split(RegExp(r'[\s-]')).last;
                 // Check if last part is digit
                 if (RegExp(r'^\d+$').hasMatch(lastChar)) {
                   semester = lastChar;
                 } else {
                   // Check if last part is roman
                   final cleanRoman = _cleanAndConvertSemester(lastChar);
                   if (cleanRoman != 'N/A') semester = cleanRoman;
                 }
              }
            } else if (label.contains('batch') || label.contains('year') || label.contains('admission')) {
              if (batch.isEmpty) batch = value;
            } else if (label.contains('father')) {
              if (fatherName.isEmpty) fatherName = value;
            } else if (label.contains('mother')) {
              if (motherName.isEmpty) motherName = value;
            } else if (label.contains('address')) {
              if (address.isEmpty) address = value;
            }
          }
        }
      }
      
      // Also try to extract email from body text using regex
      if (email.isEmpty) {
        final emailMatch = RegExp(r'[\w\.-]+@[\w\.-]+\.\w+').firstMatch(bodyText);
        if (emailMatch != null) {
          email = emailMatch.group(0) ?? '';
          print('GmsScraperService: Found email from regex: $email');
        }
      }

      // ---------------------------------------------------------
      // ROBUST FALLBACK: Regex for Semester
      // ---------------------------------------------------------
      if (semester.isEmpty) {
         // Regex to find "Semester : 5" or "Sem: V" or "Current Sem - 3"
         // Matches: Label + separator + Value (digits or roman)
         final semRegex = RegExp(
           r'(?:semester|sem|term|current\s*sem)\s*[:\.-]?\s*([0-9]+|[IVX]+)', 
           caseSensitive: false
         );
         
         final match = semRegex.firstMatch(bodyText);
         if (match != null) {
           final semRaw = match.group(1) ?? '';
           final semClean = _cleanAndConvertSemester(semRaw);
           if (semClean.isNotEmpty && semClean != 'N/A') {
             semester = semClean;
             print('GmsScraperService: Found semester using regex fallback: $semester (raw: $semRaw)');
           }
         }
      }
      
      // If semester is still empty, calculate from Enrollment Number fallback
      if (semester.isEmpty && enrollment.length >= 7) {
         try {
           // Enrollment format YYYY... or YY... Check length
           // e.g. 1250222... -> 22 is year. Position 5,6.
           final yearStr = enrollment.substring(5, 7); 
           final enrollYear = int.parse('20$yearStr');
           final now = DateTime.now();
           int sem = (now.year - enrollYear) * 2;
           if (now.month >= 7) sem += 1; // July-Dec is Odd sem
           
           if (sem > 0 && sem <= 8) {
             semester = sem.toString();
             print('GmsScraperService: Calculated semester from enrollment: $semester');
           }
         } catch (e) {
           print('GmsScraperService: Could not calculate semester: $e');
         }
      }
      
      // Extract registered courses using REGEX on raw HTML
      // The HTML parser struggles with malformed <tr> tags, so we use regex instead
      // Table structure: Sr No (0), Course Code (1), Course Name (2), Practical Batch (3), Class (4), Semester (5), Elective (6)
      
      final htmlString = welcomeResponse.data.toString();
      print('GmsScraperService: Parsing courses from HTML (length: ${htmlString.length})');
      
      // Find all td elements with tablematerial1 or tablematerial2 class using regex
      // Pattern: <td class="tablematerial1">content</td> or <td class="tablematerial2">content</td>
      final tdPattern = RegExp(
        r'<td\s+class="tablematerial[12]"[^>]*>(.*?)</td>',
        caseSensitive: false,
        dotAll: true,
      );
      
      final matches = tdPattern.allMatches(htmlString).toList();
      print('GmsScraperService: Found ${matches.length} td matches with regex');
      
      // Each course has 7 columns
      const int columnsPerRow = 7;
      final int numCourses = matches.length ~/ columnsPerRow;
      print('GmsScraperService: Detected $numCourses courses from ${matches.length} cells');
      
      for (int i = 0; i < numCourses; i++) {
        final startIdx = i * columnsPerRow;
        
        if (startIdx + 6 < matches.length) {
          // Extract text content, removing HTML tags and cleaning up
          String extractText(RegExpMatch match) {
            String text = match.group(1)?.replaceAll(RegExp(r'<[^>]*>'), '').trim() ?? '';
            // Remove non-printable characters and extra whitespace
            text = text.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
            return text;
          }
          
          final srNo = extractText(matches[startIdx]);
          final code = extractText(matches[startIdx + 1]);
          final courseName = extractText(matches[startIdx + 2]);
          final practicalBatch = extractText(matches[startIdx + 3]);
          final classSection = extractText(matches[startIdx + 4]);
          final semValue = extractText(matches[startIdx + 5]);
          
          print('GmsScraperService: Course ${i+1} - sr: "$srNo", code: "$code", name: "$courseName", batch: "$practicalBatch", class: "$classSection", sem: "$semValue"');
          
          if (code.isNotEmpty && courseName.isNotEmpty) {
            courses.add(RegisteredCourse(
              code: code,
              name: courseName,
              type: practicalBatch,
            ));
            
            // Extract semester and section from first course row if not set
            // Section uses Practical Batch (column 3) as requested
            if (semester.isEmpty && semValue.isNotEmpty) {
              // Clean and convert semester value
              semester = _cleanAndConvertSemester(semValue);
              print('GmsScraperService: Set semester from course: $semester');
            }
            if (section.isEmpty && practicalBatch.isNotEmpty) {
              section = practicalBatch;
              print('GmsScraperService: Set section from practical batch: $section');
            }
          }
        }
      }
      
      print('GmsScraperService: Extracted ${courses.length} courses from welcome page using regex');

      // -----------------------------------------------------------------------
      // FINAL ROBUST SEMESTER STRATEGY (Based on User Inputs)
      // -----------------------------------------------------------------------
      if (semester.isEmpty) {
        // The user provided HTML shows <table class="tablematerial">
        // Data is in <td class="tablematerial1"> or <td class="tablematerial2">
        // Column Index 5 is Semester (0-indexed: Sr[0], Code[1], Name[2], Batch[3], Class[4], Semester[5])
        
        // AGGRESSIVE SCAPING STRATEGY
        // 1. Iterate ALL tables
        // 2. Find header row
        // 3. Dynamically find "Semester" column index
        // 4. Extract from data rows
        
        for (final table in tables) {
           final rows = table.querySelectorAll('tr');
           if (rows.length > 1) { 
              // Try to find header row (usually first)
              final headerCells = rows[0].querySelectorAll('th, td');
              
              int semesterColIdx = -1;
              bool isCourseTable = false;
              
              // Analyze headers - DEBUG VERBOSE
              String headerLog = 'GmsScraperService: Analyzing Table headers: ';
              for (int i = 0; i < headerCells.length; i++) {
                  final text = headerCells[i].text.toLowerCase().trim();
                  headerLog += '[$i="$text"] ';
                  
                  // Check for "Semester", "Sem", "Sem." etc.
                  if (text.contains('semester') || text.startsWith('sem')) {
                      semesterColIdx = i;
                  }
                  if (text.contains('course') || text.contains('subject')) {
                      isCourseTable = true;
                  }
              }
              print(headerLog);
              
              // If we found a semester column, this is likely the table we want
              // (Subject to isCourseTable check to avoid false positives like "Sem 1" links in menu)
              if (semesterColIdx != -1 && isCourseTable) {
                  print('GmsScraperService: Found Semester column at index $semesterColIdx in a Course table');
                  
                  // Scrape from data rows
                  final Map<String, int> semesterCounts = {};
                  
                  for (int i = 1; i < rows.length; i++) {
                      final cells = rows[i].querySelectorAll('td');
                      if (cells.length > semesterColIdx) {
                          final rawSem = cells[semesterColIdx].text.trim();
                          
                          final clean = _cleanAndConvertSemester(rawSem);
                          if (clean.isNotEmpty && clean != 'N/A') {
                              semesterCounts[clean] = (semesterCounts[clean] ?? 0) + 1;
                          }
                      }
                  }
                  
                  // Find most frequent semester (Mode)
                  if (semesterCounts.isNotEmpty) {
                      var bestSem = '';
                      var maxCount = 0;
                      semesterCounts.forEach((sem, count) {
                          if (count > maxCount) {
                              maxCount = count;
                              bestSem = sem;
                          }
                      });
                      
                      if (bestSem.isNotEmpty) {
                          semester = bestSem;
                          print('GmsScraperService: SUCCESS! Inferred semester "$semester" from $maxCount rows in Course Table');
                      }
                  }
              }
              if (semester.isNotEmpty) break;
           }
        }
      }
      
      if (semester.isEmpty) {
         print('GmsScraperService: WARNING - Semester extraction FAILED after checking all tables.');
         if (tables.isNotEmpty) {
             print('GmsScraperService: Dumping 1st Table Headers for debugging:');
             final hRows = tables.first.querySelectorAll('tr');
             if (hRows.isNotEmpty) {
                 print('Header Row: ${hRows.first.text.trim()}');
             }
             // Dump raw HTML of the first table to see if we are even looking at the right thing
             final tableHtml = tables.first.outerHtml;
             print('Table HTML dump (first 500 chars): ${tableHtml.substring(0, tableHtml.length > 500 ? 500 : tableHtml.length)}');
         } else {
             print('GmsScraperService: No tables found in Welcome page!');
         }
      }
      
      // If still empty (legacy logic for registered courses inference)
      if (semester.isEmpty && courses.isNotEmpty) {
          // ... (keep fallback or remove if confident)
      }

      // If branch is still empty, try to infer from enrollment number
      // Format: 12502XXYYY where XX is branch code at position 5-6 (0-indexed)
      // e.g., 12502080503001 -> branch code is "08" (IT)
      if (branch.isEmpty && enrollment.length >= 7) {
        final branchCode = enrollment.substring(5, 7);
        final branchMap = {
          '04': 'Computer Department',
          '09': 'Mechanical Department',
          '08': 'Information Technology',
          '13': 'Computer Science and Design',
          '06': 'Electronic and Communication',
          '05': 'Electrical Department',
          '03': 'Civil Department',
          '11': 'CSE and IoT',
          '10': 'Mechatronics',
          '02': 'Chemical',
          // '23': 'Information & Communication Technology', // Uncomment if needed, or rely on user's list. User included 23.
          '23': 'Information & Communication Technology',
        };
        if (branchMap.containsKey(branchCode)) {
          branch = branchMap[branchCode]!;
          print('GmsScraperService: Inferred branch from enrollment: $branch (code: $branchCode)');
        }
      }

    } catch (e) {
      print('GmsScraperService: Error scraping profile: $e');
    }



    print('GmsScraperService: Final extracted - name: "$name", sem: "$semester", sec: "$section", batch: "$batch"');

    // Sanitize all fields
    return Student(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.isNotEmpty && name.length > 2 ? name : 'Student',
      rollNumber: enrollment,
      enrollment: enrollment,
      email: email,
      phone: _sanitizeField(phone),
      branch: _sanitizeField(branch),
      semester: _sanitizeField(semester),
      section: _sanitizeField(section),
      batch: _sanitizeField(batch),
      fatherName: _sanitizeField(fatherName),
      motherName: _sanitizeField(motherName),
      address: _sanitizeField(address),
      registeredCourses: courses,
    );
  }

  /// Sanitize scraped field value to remove garbage data like menu items
  String _sanitizeField(String value) {
    if (value.isEmpty) return '';
    
    // List of known garbage/menu text patterns to filter out
    // REMOVED 'semester', 'sem X' types as they are valid values
    const garbagePatterns = [
      'home', 'material', 'view uploaded', 'view attendance', 
      'quiz', 'quiz result', 'quiz solution', 'library',
      'academic calendar', 
      'first year', 'data entry', 'diploma', 'epaper', 'search',
      'logout', 'profile', 'change password', 'welcome', 'student',
      'select', 'choose', 'click here', 'download', 'view', 'uploaded',
    ];
    
    final lowerValue = value.toLowerCase().trim();
    
    // Check if the value looks like a menu item
    for (final pattern in garbagePatterns) {
      if (lowerValue == pattern || 
          lowerValue.startsWith(pattern) ||
          lowerValue.contains('view ') ||
          (lowerValue.contains('sem ') && !lowerValue.contains('semester') && !RegExp(r'sem\s*\d').hasMatch(lowerValue))) {
             // Exception: allow "Sem 1", "Sem 2" etc.
             if (!RegExp(r'sem\s*\d').hasMatch(lowerValue)) {
                return '';
             }
      }
    }
    
    // Check if value is too long (likely multiple concatenated items)
    if (value.length > 100) return '';
    
    // Check if value contains multiple line breaks (concatenated menu)
    if (value.split('\n').length > 2) return '';
    
    return value.trim();
  }

  /// Clean and convert semester value from Roman numerals to Arabic numerals
  String _cleanAndConvertSemester(String value) {
    if (value.isEmpty) return '';
    
    // Clean the value - remove any non-alphanumeric characters except spaces
    String cleaned = value.replaceAll(RegExp(r'[^\w\s]'), '').trim().toUpperCase();
    
    // Also remove numbers from the start if they look like serial numbers
    cleaned = cleaned.replaceAll(RegExp(r'^\d+\s*'), '').trim();
    
    // If it's already a number, return it
    if (RegExp(r'^\d+$').hasMatch(cleaned)) {
      return cleaned;
    }
    
    // Map Roman numerals to Arabic - ORDER FROM LONGEST TO SHORTEST for contains check
    const romanPatterns = [
      ['VIII', '8'],
      ['VII', '7'],
      ['VI', '6'],
      ['IV', '4'],
      ['V', '5'],
      ['III', '3'],
      ['II', '2'],
      ['I', '1'],
    ];
    
    // First try exact match
    for (final pattern in romanPatterns) {
      if (cleaned == pattern[0]) {
        return pattern[1];
      }
    }
    
    // Then try contains match (longest first to avoid partial matches)
    for (final pattern in romanPatterns) {
      if (cleaned.contains(pattern[0])) {
        return pattern[1];
      }
    }
    
    // If nothing matches, return 'N/A'
    return 'N/A';
  }

  /// Scrape attendance data
  Future<List<SubjectAttendance>> scrapeAttendance() async {
    final attendanceList = <SubjectAttendance>[];

    try {
      print('GmsScraperService: Fetching attendance from $_attendanceUrl');
      final response = await _dio.get(_attendanceUrl);
      final responseBody = response.data.toString();
      
      print('GmsScraperService: Attendance response length: ${responseBody.length}');
      print('GmsScraperService: Attendance preview: ${responseBody.substring(0, responseBody.length > 500 ? 500 : responseBody.length)}');
      
      // Check if we're logged in (not redirected to login page)
      if (responseBody.toLowerCase().contains('login_id') || 
          responseBody.toLowerCase().contains('studentlogin.jsp')) {
        print('GmsScraperService: Session expired - redirected to login page');
        return attendanceList;
      }
      
      final document = html_parser.parse(responseBody);
      final tables = document.querySelectorAll('table');
      
      print('GmsScraperService: Found ${tables.length} tables on attendance page');

      // Try multiple table detection strategies
      for (int tableIdx = 0; tableIdx < tables.length; tableIdx++) {
        final table = tables[tableIdx];
        final headerText = table.text.toLowerCase();
        
        // Broader detection: look for tables with course-related headers
        final hasCoursInfo = headerText.contains('course') || 
                             headerText.contains('subject') ||
                             headerText.contains('code');
        final hasAttendanceInfo = headerText.contains('present') || 
                                  headerText.contains('attendance') ||
                                  headerText.contains('total') ||
                                  headerText.contains('attended');
        
        print('GmsScraperService: Table $tableIdx - hasCourse: $hasCoursInfo, hasAttendance: $hasAttendanceInfo');
        
        if (hasCoursInfo || hasAttendanceInfo) {
          final rows = table.querySelectorAll('tr');
          print('GmsScraperService: Table $tableIdx has ${rows.length} rows');
          
          // Try to find the header row to understand column structure
          int codeColIdx = -1;
          int nameColIdx = -1;
          int typeColIdx = -1; // New: Type column
          int attendanceColIdx = -1;
          
          if (rows.isNotEmpty) {
            final headerCells = rows[0].querySelectorAll('th, td');
            for (int c = 0; c < headerCells.length; c++) {
              final cellText = headerCells[c].text.toLowerCase().trim();
              print('GmsScraperService: Header col $c: "$cellText"');
              
              if (cellText.contains('code') || cellText.contains('course code')) {
                codeColIdx = c;
              } else if (cellText.contains('name') || cellText.contains('course name') || cellText.contains('subject')) {
                nameColIdx = c;
              } else if (cellText == 'type' || cellText.contains('type')) {
                typeColIdx = c; // Found Type column
              } else if (cellText.contains('present') || cellText.contains('attendance') || cellText.contains('attended')) {
                attendanceColIdx = c;
              }
            }
          }
          
          print('GmsScraperService: Column indices - code: $codeColIdx, name: $nameColIdx, type: $typeColIdx, attendance: $attendanceColIdx');
          
          // Default column positions if not found from headers
          if (codeColIdx == -1) codeColIdx = 1;
          if (nameColIdx == -1) nameColIdx = 2;
          // default type column is usually after course name, let's say 3 if not found? 
          // But safer to only use if found or try to guess based on 'T'/'P' value later
          
          for (int i = 1; i < rows.length; i++) {
            final cols = rows[i].querySelectorAll('td');
            print('GmsScraperService: Row $i has ${cols.length} columns');
            
            if (cols.length >= 3) {
              try {
                final courseCode = cols.length > codeColIdx ? cols[codeColIdx].text.trim() : '';
                final courseName = cols.length > nameColIdx ? cols[nameColIdx].text.trim() : '';
                
                // Extract Type
                String typeStr = 'Theory'; // Default
                if (typeColIdx != -1 && cols.length > typeColIdx) {
                   final rawType = cols[typeColIdx].text.trim().toUpperCase();
                   if (rawType == 'P' || rawType.contains('LAB') || rawType.contains('PRACTICAL')) {
                     typeStr = 'Lab';
                   } else if (rawType == 'T' || rawType.contains('THEORY')) {
                     typeStr = 'Theory';
                   }
                } else {
                   // Fallback: check other columns for 'T' or 'P'
                   for (int c = 0; c < cols.length; c++) {
                      if (c == codeColIdx || c == nameColIdx || c == attendanceColIdx) continue;
                      final val = cols[c].text.trim().toUpperCase();
                      if (val == 'T') {
                        typeStr = 'Theory';
                        break;
                      } else if (val == 'P') {
                        typeStr = 'Lab';
                        break;
                      }
                   }
                }
                
                // Try to find attendance data - search all columns for pattern X/Y or percentage
                String presentText = '';
                for (int c = 0; c < cols.length; c++) {
                  final text = cols[c].text.trim();
                  if (RegExp(r'\d+\s*/\s*\d+').hasMatch(text) || RegExp(r'\d+\.?\d*\s*%').hasMatch(text)) {
                    presentText = text;
                    print('GmsScraperService: Found attendance in col $c: "$text"');
                    break;
                  }
                }
                
                // If still not found, use the last column
                if (presentText.isEmpty && cols.isNotEmpty) {
                  presentText = cols.last.text.trim();
                }

                print('GmsScraperService: Row $i - code: "$courseCode", name: "$courseName", type: "$typeStr", present: "$presentText"');

                final match = RegExp(r'(\d+)\s*/\s*(\d+)').firstMatch(presentText);
                final percentMatch = RegExp(r'(\d+\.?\d*)\s*%').firstMatch(presentText);

                if (match != null) {
                  final attended = int.parse(match.group(1)!);
                  final total = int.parse(match.group(2)!);
                  final percentage = percentMatch != null 
                      ? double.parse(percentMatch.group(1)!)
                      : (total > 0 ? (attended / total * 100).toDouble() : 0.0);

                  if (courseCode.isNotEmpty || courseName.isNotEmpty) {
                    attendanceList.add(SubjectAttendance(
                      subjectCode: courseCode.isNotEmpty ? courseCode : 'N/A',
                      subjectName: courseName.isNotEmpty ? courseName : 'Unknown Subject',
                      attendedClasses: attended,
                      totalClasses: total,
                      percentage: percentage,
                      type: typeStr,
                    ));
                    print('GmsScraperService: Added attendance - $courseCode ($typeStr): $attended/$total = ${percentage.toStringAsFixed(1)}%');
                  }
                } else if (percentMatch != null && (courseCode.isNotEmpty || courseName.isNotEmpty)) {
                  // If we only have percentage, try to add with estimated values
                  final percentage = double.parse(percentMatch.group(1)!);
                  attendanceList.add(SubjectAttendance(
                    subjectCode: courseCode.isNotEmpty ? courseCode : 'N/A',
                    subjectName: courseName.isNotEmpty ? courseName : 'Unknown Subject',
                    attendedClasses: 0,
                    totalClasses: 0,
                    percentage: percentage,
                    type: typeStr,
                  ));
                  print('GmsScraperService: Added attendance (percent only) - $courseCode ($typeStr): ${percentage.toStringAsFixed(1)}%');
                }
              } catch (e) {
                print('GmsScraperService: Error parsing row $i: $e');
              }
            }
          }
          
          // If we found attendance data, stop searching tables
          if (attendanceList.isNotEmpty) {
            print('GmsScraperService: Found ${attendanceList.length} attendance records from table $tableIdx');
            break;
          }
        }
      }
      
      print('GmsScraperService: Total attendance records scraped: ${attendanceList.length}');
      
    } catch (e) {
      print('GmsScraperService: Error scraping attendance: $e');
    }

    return attendanceList;
  }

  /// Helper to dynamically discover materials URL from Welcome page menu
  Future<String?> _discoverMaterialsUrl() async {
    try {
      print('GmsScraperService: Discovering materials URL from welcome page...');
      final response = await _dio.get(_welcomeUrl);
      final document = html_parser.parse(response.data.toString());
      
      // Strategy 1: Look for "View Uploaded Material" in <a> tags
      // The menu might be in a table structure as seen in logs
      final allLinks = document.querySelectorAll('a');
      for (final link in allLinks) {
        final text = link.text.toLowerCase().trim();
        if ((text.contains('view') && text.contains('uploaded') && text.contains('material')) ||
            (text.contains('material') && text.contains('search'))) {
          var href = link.attributes['href'];
          if (href != null && href.isNotEmpty && !href.startsWith('#')) {
             if (href.startsWith('..')) {
               // Resolve relative path "../Student/Page.jsp" -> "http://.../GIS/Student/Page.jsp"
               // properties: _baseUrl is .../GIS
               // URL structure: .../GIS/Student/Welcome.jsp
               // Link: ../Student/Page.jsp
               // This means we go up from Student to GIS, then to Student again?
               // Let's just handle standard patterns manually to be safe
               final cleanHref = href.replaceAll('../', '');
               return '$_baseUrl/$cleanHref';
             } else if (!href.startsWith('http')) {
               return '$_baseUrl/Student/$href';
             }
             return href;
          }
          
          // Check for onclick event (JavaScript navigation)
          // onclick="menu_action('View Uploaded Material','../Student/ViewUploadMaterialNew.jsp?id=1')"
          final onClick = link.attributes['onclick'];
          if (onClick != null) {
            final match = RegExp(r"[']([^']*Student[^']*)[']").firstMatch(onClick);
            if (match != null) {
              final path = match.group(1)!;
              final cleanPath = path.replaceAll('../', '');
              return '$_baseUrl/$cleanPath';
            }
          }
        }
      }
      
      // Strategy 2: Look in table cells (if menu is not anchors but text with JS)
      final allCells = document.querySelectorAll('td');
      for (final cell in allCells) {
         final text = cell.text.toLowerCase().trim();
         if ((text.contains('view') && text.contains('uploaded') && text.contains('material')) ||
             (text.contains('material') && text.contains('search'))) {
            // Check parent <tr> or the <td> itself for onclick
            var element = cell;
            var onClick = element.attributes['onclick'];
            
            // Look at parent if no onclick on td
            if (onClick == null && element.parent != null) {
               onClick = element.parent!.attributes['onclick'];
            }
            
            if (onClick != null) {
               // Extract URL from JS: menu_action('...','URL')
               // Regex to find something that looks like a path
               final match = RegExp(r"[']([^']*Student/[^']*)[']").firstMatch(onClick);
               if (match != null) {
                 final path = match.group(1)!;
                  // Fix: Ensure we don't create double slash/path
                  String cleanPath = path.replaceAll('../', '');
                  if (cleanPath.startsWith('/')) cleanPath = cleanPath.substring(1);
                  if (cleanPath.startsWith('GIS/')) cleanPath = cleanPath.substring(4); // BaseUrl likely has GIS
                  
                  return '$_baseUrl/$cleanPath';
               }
            }
         }
      }

    } catch (e) {
      print('GmsScraperService: Failed to discover materials URL: $e');
    }
    return null;
  }

  /// Scrape materials
  /// Supports searching by category + subject dropdown OR by text search (course code/partial name)
  Future<MaterialsResult> scrapeMaterials({String? category, String? subject, String? searchQuery}) async {
    final materials = <StudyMaterial>[];
    final categories = <DropdownOption>[];
    final subjects = <DropdownOption>[];
    
    // STEP 0: Validate session first - try to access Welcome page
    print('GmsScraperService: Validating session before fetching materials...');
    try {
      final welcomeResponse = await _dio.get(_welcomeUrl);
      final welcomeBody = welcomeResponse.data.toString().toLowerCase();
      
      final isLoggedIn = !welcomeBody.contains('studentlogin.jsp') && 
                         !welcomeBody.contains('name="login_id"') &&
                         (welcomeBody.contains('logout') || welcomeBody.contains('welcome'));
      
      if (!isLoggedIn) {
        print('GmsScraperService: Session invalid. Welcome page indicates not logged in.');
        
        // Try to re-authenticate
        if (_username != null && _password != null) {
          print('GmsScraperService: Attempting to re-authenticate...');
          final loginResult = await login(_username!, _password!, '');
          if (!loginResult.success) {
            print('GmsScraperService: Re-authentication failed: ${loginResult.error}');
            return MaterialsResult(materials: materials, categories: categories, subjects: subjects);
          }
          print('GmsScraperService: Re-authentication successful!');
        } else {
          print('GmsScraperService: No stored credentials for re-authentication.');
          return MaterialsResult(materials: materials, categories: categories, subjects: subjects);
        }
      } else {
        print('GmsScraperService: Session is valid. Proceeding to fetch materials.');
      }
    } catch (e) {
      print('GmsScraperService: Error validating session: $e');
    }
    
    // List of potential URLs to try
    final urlsToTry = <String>[];
    
    // 1. Try to discover the URL dynamically from the Welcome page menu
    final discoveredUrl = await _discoverMaterialsUrl();
    if (discoveredUrl != null && discoveredUrl.isNotEmpty) {
      print('GmsScraperService: Added discovered materials URL to priority: $discoveredUrl');
      urlsToTry.add(discoveredUrl);
    }

    // 2. Add fallback URLs - PRIORITIZE ViewUploadMaterialNew_1.jsp (USER CONFIRMED)
    urlsToTry.addAll([
      '$_baseUrl/Student/ViewUploadMaterialNew_1.jsp',    // USER CONFIRMED working URL
      '$_baseUrl/Student/ViewUploadMaterialNew.jsp',      // Most common for "Search"
      '$_baseUrl/Student/ViewUploadMaterialNew.jsp?id=1', // With param
      '$_baseUrl/Student/ViewUploadedMaterial.jsp',       // Standard list
      '$_baseUrl/Student/ViewUploadMaterial.jsp',         // Singular
      '$_baseUrl/Student/ViewMaterials.jsp',              // Alternative
      '$_baseUrl/Student/ViewMaterial.jsp',               // Singular alternative
    ]);

    String successfulUrl = '';

    for (final url in urlsToTry) {
      try {
        print('GmsScraperService: Trying URL: $url');
        final response = await _dio.get(url);
        final responseBody = response.data.toString();
        final responseLower = responseBody.toLowerCase();
        
        // Log response preview for debugging
        print('GmsScraperService: Response length: ${responseBody.length}');
        print('GmsScraperService: Response preview: ${responseBody.substring(0, responseBody.length > 300 ? 300 : responseBody.length)}');
        
        // Check if we got redirected to login page (session expired)
        final isLoginPage = responseLower.contains('studentlogin.jsp') || 
                            responseLower.contains('name="login_id"') ||
                            (responseLower.contains('password') && responseLower.contains('enrollment'));
        
        if (isLoginPage) {
           print('GmsScraperService: Session expired - redirected to login at $url');
           continue; // Try next URL (or re-authenticate)
        }
        
        // Check if we got a valid page (status 200 and not error page)
        if (response.statusCode == 200) {
           final document = html_parser.parse(responseBody);
           final methodSelects = document.querySelectorAll('select');
           final courseInput = document.querySelector('input[name="course_code"]');
           final categorySelect = document.querySelector('select[name="category_name"]');
           
           print('GmsScraperService: Found ${methodSelects.length} selects, course input: ${courseInput != null}, category: ${categorySelect != null}');
           
           // Heuristic: If we find at least 1 select (Category) or input (Course Code), likely success
           // The new page has 1 select and 1 text input
           if (methodSelects.isNotEmpty || courseInput != null) {
             print('GmsScraperService: Found valid page at $url');
             successfulUrl = url;
             
             // Extract Dropdowns generically
             _extractDropdowns(document, categories, subjects);
              
             // If we found a valid page structure, break
             break;
           } else {
             print('GmsScraperService: Page at $url does not have expected form elements');
           }
        }
      } catch (e) {
        print('GmsScraperService: Failed to fetch $url: $e');
      }
    }
    
    if (successfulUrl.isEmpty) {
      print('GmsScraperService: All URLs failed to return a valid materials page.');
      
      // Try to re-authenticate if we have stored credentials
      if (_username != null && _password != null) {
        print('GmsScraperService: Attempting session re-authentication...');
        final reLoginResult = await login(_username!, _password!, '');
        
        if (reLoginResult.success) {
          print('GmsScraperService: Re-authentication successful! Retrying first URL...');
          // Try the first priority URL again after re-login
          try {
            final firstUrl = urlsToTry.isNotEmpty ? urlsToTry.first : _materialsUrl;
            final response = await _dio.get(firstUrl);
            final responseBody = response.data.toString();
            
            if (response.statusCode == 200) {
              final document = html_parser.parse(responseBody);
              final methodSelects = document.querySelectorAll('select');
              
              if (methodSelects.isNotEmpty || document.querySelector('input[name="course_code"]') != null) {
                print('GmsScraperService: Found valid page after re-auth at $firstUrl');
                successfulUrl = firstUrl;
                _extractDropdowns(document, categories, subjects);
              }
            }
          } catch (e) {
            print('GmsScraperService: Failed to fetch after re-auth: $e');
          }
        } else {
          print('GmsScraperService: Re-authentication failed: ${reLoginResult.error}');
        }
      }
      
      // Final fallback if still no success
      if (successfulUrl.isEmpty) {
        successfulUrl = _materialsUrl;
      }
    }

    try {
      // Perform Search if requested
      if (searchQuery != null || (category != null && subject != null)) {
         // ... existing search logic ...
         // Note: We need to use successfulUrl for the POST request
         final targetUrl = successfulUrl.isNotEmpty ? successfulUrl : _materialsUrl;
         
         final data = <String, dynamic>{};
         // The new page uses 'course_code' input for search text.
         // We send both keys to be safe across different page versions.
         if (searchQuery != null) {
           data['search_key'] = searchQuery;
           data['course_code'] = searchQuery; 
         }
         if (category != null) data['category_name'] = category;
         if (subject != null) data['course_code'] = subject;
         
         final searchResponse = await _dio.post(
            targetUrl,
            data: data,
            options: Options(contentType: Headers.formUrlEncodedContentType),
         );
         final searchDoc = html_parser.parse(searchResponse.data.toString());
         _extractMaterialsFromDocument(searchDoc, materials, subject ?? 'Result', category ?? 'Material');
      } 
      // Initial Load: If no specific search params
      else if (successfulUrl.isNotEmpty) {
         // Re-fetch the successful page
         print('GmsScraperService: Fetching default view from $successfulUrl');
         final response = await _dio.get(successfulUrl);
         final doc = html_parser.parse(response.data.toString());
         
         // FIRST ATTEMPT: Extract materials directly from GET response
         // This works if the page shows materials by default
         int initialCount = materials.length;
         _extractMaterialsFromDocument(doc, materials, 'Recent', 'General');
         
         // FALLBACK: If GET yielding nothing (likely an empty search form), 
         // Force a "Show All" search by POSTing empty parameters
          if (materials.length == initialCount) {
             print('GmsScraperService: No materials in default view. Attempting "Show All" fallback search...');
             
             final targetUrl = successfulUrl;
             final data = <String, dynamic>{
                'search_key': '', // Empty search key
                'course_code': '', // Empty course code
                // Try sending % as wildcard if server supports it, otherwise empty usually means all
             };
             
             try {
               final searchResponse = await _dio.post(
                  targetUrl,
                  data: data,
                  options: Options(contentType: Headers.formUrlEncodedContentType),
               );
               final searchDoc = html_parser.parse(searchResponse.data.toString());
               
               // Extract materials from search result
               _extractMaterialsFromDocument(searchDoc, materials, 'All Recent', 'General');
               
               // CRITICAL: Also try to extract dropdowns from the search result page
               // The initial page might have been empty, but the result page likely has the filter options
               if (categories.isEmpty || subjects.isEmpty) {
                   print('GmsScraperService: Initial dropdowns were empty. Extracting from search result...');
                   _extractDropdowns(searchDoc, categories, subjects);
               }
               
               // CRITICAL: Also try to extract dropdowns from the search result page
               // The initial page might have been empty, but the result page likely has the filter options
               if (categories.isEmpty || subjects.isEmpty) {
                   print('GmsScraperService: Initial dropdowns were empty. Extracting from search result...');
                   _extractDropdowns(searchDoc, categories, subjects);
               }
               
             } catch (e) {
               print('GmsScraperService: Fallback search failed: $e');
             }
         }
      }

    } catch (e) {
      print('GmsScraperService: Error parsing search results: $e');
    }

    return MaterialsResult(
      materials: materials,
      categories: categories,
      subjects: subjects,
    );
  }
  
  /// Helper method to extract materials from document
  /// GMS Materials Table Structure (based on actual website):
  /// Col 0: Sr No
  /// Col 1: Staff Name (uploadedBy)
  /// Col 2: Category (type)
  /// Col 3: Course Code (subjectCode)
  /// Col 4: Course Name (title / subjectName)
  /// Col 5: Description
  /// Col 6: Academic Year
  /// Col 7: Uploaded on (uploadedAt)
  /// Col 8: Last date
  /// Col 9: View link (url)
  void _extractMaterialsFromDocument(dynamic doc, List<StudyMaterial> materials, String subjectIdentifier, String category) {
    print('GmsScraperService: Extracting materials for $subjectIdentifier');
    final tables = doc.querySelectorAll('table');
    print('GmsScraperService: Found ${tables.length} tables in search result');

    for (int t = 0; t < tables.length; t++) {
      final table = tables[t];
      final tableText = table.text.toLowerCase();
      print('GmsScraperService: Checking table $t with approx ${tableText.length} chars');
      
      // Look for materials table by checking for key column headers
      final hasStaffName = tableText.contains('staff name') || tableText.contains('faculty');
      final hasCourseCode = tableText.contains('course code');
      final hasCourseName = tableText.contains('course name');
      final hasUploaded = tableText.contains('uploaded');
      final hasView = tableText.contains('view');
      
      print('GmsScraperService: Table $t - staffName:$hasStaffName, courseCode:$hasCourseCode, courseName:$hasCourseName, uploaded:$hasUploaded, view:$hasView');
      
      if (hasStaffName || hasCourseCode || hasCourseName || (hasUploaded && hasView)) {
        print('GmsScraperService: Table $t matches materials criteria!');
        final rows = table.querySelectorAll('tr');
        print('GmsScraperService: Found ${rows.length} rows in table $t');
        
        // Skip header row (index 0)
        for (int i = 1; i < rows.length; i++) {
          final cols = rows[i].querySelectorAll('td');
          print('GmsScraperService: Row $i has ${cols.length} columns');
          
          if (cols.length >= 5) {
            try {
              // Extract data based on actual GMS structure
              // Sr No (0), Staff Name (1), Category (2), Course Code (3), Course Name (4), 
              // Description (5), Academic Year (6), Uploaded on (7), Last date (8), View (9)
              
              final staffName = cols.length > 1 ? cols[1].text.trim() : 'Faculty';
              final categoryText = cols.length > 2 ? cols[2].text.trim() : category;
              final courseCode = cols.length > 3 ? cols[3].text.trim() : '';
              final courseName = cols.length > 4 ? cols[4].text.trim() : 'Untitled';
              final description = cols.length > 5 ? cols[5].text.trim() : '';
              final academicYear = cols.length > 6 ? cols[6].text.trim() : '';
              final uploadedOn = cols.length > 7 ? cols[7].text.trim() : '';
              
              // Find download URL from the View link (usually in last column)
              String? downloadUrl;
              // Search all columns for links
              for (int c = 0; c < cols.length; c++) {
                final link = cols[c].querySelector('a');
                if (link != null) {
                  final href = link.attributes['href'];
                  if (href != null && href.isNotEmpty) {
                    String url = href.trim();
                    
                    // Already absolute URL
                    if (url.startsWith('http://') || url.startsWith('https://')) {
                      downloadUrl = url;
                    }
                    // Absolute path starting with /store/ or /GIS/
                    else if (url.startsWith('/')) {
                      downloadUrl = 'http://202.129.240.148:8080$url';
                    }
                    // Relative path going up directories (e.g., ../../store/...)
                    else if (url.startsWith('../')) {
                      // Count how many levels up
                      String cleanUrl = url;
                      while (cleanUrl.startsWith('../')) {
                        cleanUrl = cleanUrl.substring(3);
                      }
                      // Most likely points to /store/ from /GIS/Student/
                      downloadUrl = 'http://202.129.240.148:8080/$cleanUrl';
                    }
                    // Simple relative path (add to current base)
                    else {
                      downloadUrl = 'http://202.129.240.148:8080/GIS/Student/$url';
                    }
                    
                    // URL encode spaces if not already encoded
                    if (downloadUrl.contains(' ')) {
                      downloadUrl = downloadUrl.replaceAll(' ', '%20');
                    }
                    
                    print('GmsScraperService: Found download URL in col $c: $downloadUrl');
                    break;
                  }
                }
              }
              
              // Create title combining course name and description
              String title = courseName;
              if (description.isNotEmpty && description != '-') {
                title = '$courseName - $description';
              }
              
              print('GmsScraperService: Extracted material - code: $courseCode, name: $courseName, staff: $staffName, category: $categoryText, url: $downloadUrl');
              
              // Only add if we have meaningful data
              if (courseCode.isNotEmpty || courseName.isNotEmpty && courseName != '-') {
                materials.add(StudyMaterial(
                  id: '${DateTime.now().millisecondsSinceEpoch}_$t$i',
                  title: title,
                  subjectCode: courseCode.isNotEmpty ? courseCode : subjectIdentifier,
                  subjectName: courseName.isNotEmpty ? courseName : subjectIdentifier,
                  type: categoryText.isNotEmpty ? categoryText : category,
                  uploadedBy: staffName.isNotEmpty ? staffName : 'Faculty',
                  uploadedAt: uploadedOn.isNotEmpty ? uploadedOn : academicYear,
                  url: downloadUrl,
                ));
                print('GmsScraperService: Added material successfully!');
              }
            } catch (e) {
              print('GmsScraperService: Error parsing row $i: $e');
            }
          }
        }
        
        // If we found materials in this table, don't check other tables
        if (materials.isNotEmpty) {
          print('GmsScraperService: Found ${materials.length} materials in table $t');
          break;
        }
      }
    }
    
    print('GmsScraperService: Total materials extracted: ${materials.length}');
  }

  /// Scrape quiz results
  Future<List<Quiz>> scrapeQuizzes() async {
    final quizzes = <Quiz>[];

    try {
      final response = await _dio.get(_quizUrl);
      final document = html_parser.parse(response.data.toString());

      for (final select in document.querySelectorAll('select')) {
        for (final option in select.querySelectorAll('option')) {
          final value = option.attributes['value'] ?? '';
          if (value.isNotEmpty) {
            quizzes.add(Quiz(
              id: value,
              title: option.text.trim(),
              subjectCode: '',
              subjectName: option.text.trim(),
              status: 'completed',
            ));
          }
        }
      }

      final tables = document.querySelectorAll('table');
      for (final table in tables) {
        final rows = table.querySelectorAll('tr');
        for (int i = 1; i < rows.length; i++) {
          final cols = rows[i].querySelectorAll('td');
          if (cols.length >= 3) {
            quizzes.add(Quiz(
              id: '${DateTime.now().millisecondsSinceEpoch}$i',
              title: cols[0].text.trim(),
              subjectCode: cols.length > 1 ? cols[1].text.trim() : '',
              subjectName: cols.length > 1 ? cols[1].text.trim() : '',
              score: cols.length > 2 ? int.tryParse(cols[2].text.trim()) : null,
              status: 'completed',
            ));
          }
        }
      }
    } catch (e) {
      print('GmsScraperService: Error scraping quizzes: $e');
    }

    return quizzes;
  }

  /// Scrape library books
  Future<List<Book>> scrapeLibraryBooks() async {
    final books = <Book>[];

    try {
      final response = await _dio.get(_libraryUrl);
      final document = html_parser.parse(response.data.toString());
      final tables = document.querySelectorAll('table');

      for (final table in tables) {
        if (table.text.contains('Book') || table.text.contains('Title')) {
          final rows = table.querySelectorAll('tr');
          for (int i = 1; i < rows.length; i++) {
            final cols = rows[i].querySelectorAll('td');
            if (cols.length >= 3) {
              books.add(Book(
                id: '${DateTime.now().millisecondsSinceEpoch}$i',
                title: cols.length > 1 ? cols[1].text.trim() : 'Unknown',
                author: cols.length > 2 ? cols[2].text.trim() : '',
                issueDate: cols.length > 3 ? cols[3].text.trim() : '',
                dueDate: cols.length > 4 ? cols[4].text.trim() : '',
                status: 'issued',
              ));
            }
          }
          break;
        }
      }
    } catch (e) {
      print('GmsScraperService: Error scraping library: $e');
    }

    return books;
  }

  /// Scrape calendar events
  Future<List<CalendarEvent>> scrapeCalendarEvents() async {
    final events = <CalendarEvent>[];

    try {
      final response = await _dio.get(_calendarUrl);
      final document = html_parser.parse(response.data.toString());
      final tables = document.querySelectorAll('table');

      for (final table in tables) {
        final rows = table.querySelectorAll('tr');
        for (int i = 1; i < rows.length; i++) {
          final cols = rows[i].querySelectorAll('td');
          if (cols.length >= 2) {
            events.add(CalendarEvent(
              id: '${DateTime.now().millisecondsSinceEpoch}$i',
              title: cols.length > 1 ? cols[1].text.trim() : 'Event',
              date: cols[0].text.trim(),
              description: cols.length > 2 ? cols[2].text.trim() : '',
              type: 'academic',
            ));
          }
        }
      }
    } catch (e) {
      print('GmsScraperService: Error scraping calendar: $e');
    }

    return events;
  }

  /// Set session (for restoring from storage)
  void setSession(String sessionCookie) {
    if (sessionCookie.isEmpty) return;
    
    // For Web: Extract JSESSIONID specifically for URL rewriting
    if (kIsWeb) {
      final match = RegExp(r'JSESSIONID=([^;]+)', caseSensitive: false).firstMatch(sessionCookie);
      if (match != null) {
        _webSessionId = match.group(1);
      }
    }
    
    // sessionCookie format: "name=value; name2=value2"
    final cookies = <Cookie>[];
    final parts = sessionCookie.split(';');
    for (final part in parts) {
      final text = part.trim();
      final index = text.indexOf('=');
      if (index > 0) {
        final name = text.substring(0, index);
        final value = text.substring(index + 1);
        cookies.add(Cookie(name, value));
      }
    }
    
    if (cookies.isNotEmpty) {
      _cookieJar.saveFromResponse(Uri.parse(_baseUrl), cookies);
      _cookieJar.saveFromResponse(Uri.parse(_loginUrl), cookies);
      _cookieJar.saveFromResponse(Uri.parse(_welcomeUrl), cookies);
    }
  }

  /// Clear session
  void clearSession() {
    _cookieJar.deleteAll();
    _username = null;
    _password = null;
  }

  /// Check if session is valid
  Future<bool> isSessionValid() async {
    try {
      final response = await _dio.get(_welcomeUrl);
      final body = response.data.toString().toLowerCase();
      // Explicitly check if we are on login page
      if (body.contains('login_id') || body.contains('studentlogin.jsp')) {
        return false;
      }
      return body.contains('welcome') || body.contains('logout');
    } catch (e) {
      return false;
    }
  }

  static String get _midSem1Url => '$_baseUrl/Stu_ViewMidSemMarks.jsp';
  static String get _midSem2Url => '$_baseUrl/Stu_ViewRemedialMarks.jsp'; // Remedial/2nd Mid Sem
  static String get _remedialResultUrl => '$_baseUrl/UM.jsp';
  static String get _quizSolutionUrl => '$_baseUrl/Student/ViewSolution.jsp';

  /// Scrape Mid Semester Marks
  /// examType: 1 = First Mid Sem, 2 = Second Mid Sem / Remedial
  Future<List<MidSemResult>> scrapeMidSemMarks(int examType) async {
    final results = <MidSemResult>[];
    final url = examType == 1 ? _midSem1Url : _midSem2Url;

    try {
      final response = await _dio.get(url);
      final document = html_parser.parse(response.data.toString());
      final tables = document.querySelectorAll('table');

      for (final table in tables) {
        final headerText = table.text.toLowerCase();
        if (headerText.contains('course') && (headerText.contains('mark') || headerText.contains('total'))) {
          final rows = table.querySelectorAll('tr');
          // Start from index 1 to skip header
          for (int i = 1; i < rows.length; i++) {
            final cols = rows[i].querySelectorAll('td');
            if (cols.length >= 3) {
              final code = cols.length > 1 ? cols[1].text.trim() : '';
              final name = cols.length > 2 ? cols[2].text.trim() : '';
              
              // Try to find marks column (usually 4th or 5th)
              double marks = 0;
              double total = 30; // Default total for mid sem

              // Scan columns for numbers
              for (int j = 3; j < cols.length; j++) {
                 final text = cols[j].text.trim();
                 final value = double.tryParse(text);
                 if (value != null) {
                    marks = value;
                    break; 
                 }
              }

              if (code.isNotEmpty) {
                results.add(MidSemResult(
                  subjectCode: code,
                  subjectName: name,
                  marks: marks,
                  totalMarks: total,
                ));
              }
            }
          }
        }
      }
    } catch (e) {
      print('GmsScraperService: Error scraping mid sem marks: $e');
    }
    return results;
  }

  /// Get Exam Paper Links (Static from menu)
  List<ExamPaperLink> getExamPaperLinks() {
    return [
      ExamPaperLink(
        title: 'Mid SEM ePaper (Current)', 
        url: 'https://drive.google.com/drive/folders/1sM_PjyU_aFBywSsdtCIxQwAcJjGsEfnD?usp=sharing'
      ),
      ExamPaperLink(
        title: 'Mid SEM ePaper (AY2024-25)', 
        url: 'https://drive.google.com/drive/folders/1C22Uua3mp_AOED7hVVdB4ulLidIr-1OP?usp=sharing'
      ),
    ];
  }

  /// Scrape Quiz Solutions
  Future<List<Quiz>> scrapeQuizSolutions() async {
    final solutions = <Quiz>[];
    try {
      final response = await _dio.get(_quizSolutionUrl);
      final document = html_parser.parse(response.data.toString());
      
      final tables = document.querySelectorAll('table');
      for (final table in tables) {
        final rows = table.querySelectorAll('tr');
        for (int i = 1; i < rows.length; i++) {
          final cols = rows[i].querySelectorAll('td');
          if (cols.length >= 2) {
             final name = cols[1].text.trim();
             if (name.isNotEmpty) {
               solutions.add(Quiz(
                 id: 'sol_$i',
                 title: name,
                 subjectCode: '',
                 subjectName: name,
                 status: 'Solution Available',
                 startTime: DateTime.now(),
                 endTime: DateTime.now(),
                 durationMinutes: 0,
                 totalQuestions: 0,
               ));
             }
          }
        }
      }
    } catch (e) {
       print('GmsScraperService: Error scraping quiz solutions: $e');
    }
    return solutions;
  }

  /// Helper to extract dropdowns from a document
  void _extractDropdowns(dynamic document, List<DropdownOption> categories, List<DropdownOption> subjects) {
      if (document == null) return;
      
      final methodSelects = document.querySelectorAll('select');
      print('GmsScraperService: _extractDropdowns found ${methodSelects.length} select elements');
      
      // 1. Try to identify Category Dropdown
      var catSelect = document.querySelector('select[name="category_name"]');
      // Fallback
      if (catSelect == null && methodSelects.isNotEmpty) {
         // Heuristic: Category often comes first or has specific options
         print('GmsScraperService: Category select helper fallback to first select');
         catSelect = methodSelects.first;
      }
      
      if (catSelect != null) {
        // Avoid duplicates if we're calling this multiple times
        final existing = categories.map((c) => c.value).toSet();
        print('GmsScraperService: Found Category select. Options: ${catSelect.children.length}');
        
        for (final option in catSelect.querySelectorAll('option')) {
          final value = option.attributes['value'] ?? '';
          if (value.isNotEmpty && !existing.contains(value)) {
            print('GmsScraperService: Found Category: $value - ${option.text}');
            categories.add(DropdownOption(value: value, name: option.text.trim()));
          }
        }
      } else {
         print('GmsScraperService: NO Category select found!');
      }

      // 2. Try to identify Subject/Course Dropdown
      var subjSelect = document.querySelector('select[name="course_code"]');
      if (subjSelect != null) {
        final existing = subjects.map((s) => s.value).toSet();
        print('GmsScraperService: Found Subject select. Options: ${subjSelect.children.length}');
        
        for (final option in subjSelect.querySelectorAll('option')) {
          final value = option.attributes['value'] ?? '';
          if (value.isNotEmpty && !existing.contains(value)) {
            print('GmsScraperService: Found Subject: $value - ${option.text}');
            subjects.add(DropdownOption(value: value, name: option.text.trim()));
          }
        }
      } else {
         print('GmsScraperService: NO Subject select found!');
      }
  }
}

/// Result of captcha fetch
class GmsCaptchaResult {
  final bool success;
  final bool hasCaptcha;
  final Uint8List? captchaImage;
  final String? sessionCookie;
  final String? error;

  GmsCaptchaResult({
    required this.success,
    this.hasCaptcha = false,
    this.captchaImage,
    this.sessionCookie,
    this.error,
  });
}

/// Result of login attempt
class GmsLoginResult {
  final bool success;
  final Student? student;
  final String? sessionCookie;
  final String? error;

  GmsLoginResult({
    required this.success,
    this.student,
    this.sessionCookie,
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

