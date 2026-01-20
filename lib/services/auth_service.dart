import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';
import '../models/student_model.dart';
import 'cache_service.dart';
import 'gms_scraper_service.dart';
import 'supabase_service.dart';

/// Authentication service using direct GMS portal communication.
/// Works directly from the app without any backend server.
class AuthService extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final GmsScraperService _gmsService = GmsScraperService();
  final CacheService _cacheService = CacheService();
  bool _isOffline = false;
  bool _isDemoMode = false;
  
  Student? _currentUser;
  String? _sessionCookie;
  bool _isLoading = false;
  String? _error;
  Uint8List? _captchaImageBytes;
  bool _hasCaptcha = false;

  Student? get currentUser => _currentUser;
  String? get sessionCookie => _sessionCookie;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Uint8List? get captchaImageBytes => _captchaImageBytes;
  bool get hasCaptcha => _hasCaptcha;
  bool get isLoggedIn => _currentUser != null;
  bool get isOffline => _isOffline;
  bool get isDemoMode => _isDemoMode;
  
  /// Get the GMS scraper service for data fetching
  GmsScraperService get gmsService => _gmsService;

  /// Set online status (call after successful data refresh)
  void setOnline() {
    if (_isOffline) {
      _isOffline = false;
      notifyListeners();
    }
  }

  /// Set offline status (call if data fetch fails)
  void setOffline() {
    if (!_isOffline) {
      _isOffline = true;
      notifyListeners();
    }
  }

  /// Initialize session (fetch login page)
  Future<void> fetchCaptcha() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _gmsService.fetchCaptcha();
      
      if (result.success) {
        _captchaImageBytes = result.captchaImage;
        _hasCaptcha = result.hasCaptcha;
        _sessionCookie = result.sessionCookie;
      } else {
        _error = result.error ?? 'Failed to connect to GMS';
      }
    } catch (e) {
      _error = 'Cannot connect to GMS portal. Please check your internet connection.';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Login with credentials
  Future<bool> login(String username, String password, String captcha) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    debugPrint('AuthService.login: Starting login for $username');

    // Admin Login Check
    if (username == '30912846' && password == '30918869') {
      _currentUser = Student(
        id: 'admin',
        name: 'Administrator',
        rollNumber: 'admin',
        enrollment: 'admin',
        branch: 'ADMIN',
        semester: 'N/A',
        section: 'N/A',
        batch: 'N/A',
        email: 'admin@gcet.ac.in',
        mentorName: 'N/A',
        mentorEmail: 'N/A',
        registeredCourses: [],
      );
      _sessionCookie = 'admin_session';
      _isOffline = false;
      _isLoading = false;
      notifyListeners();
      return true;
    }



    try {
      // 1. Check for User Restriction (Supabase)
      final isRestricted = await SupabaseService().isUserRestricted(username);
      if (isRestricted) {
        _error = 'You cannot login. Contact Admin: mygcet.official.53@gmail.com';
        debugPrint('AuthService.login: User $username is restricted.');
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final result = await _gmsService.login(username, password, captcha);
      debugPrint('AuthService.login: Result - success: ${result.success}, error: ${result.error}');
      
      if (result.success && result.student != null) {
        _currentUser = result.student;
        _sessionCookie = result.sessionCookie;
        debugPrint('AuthService.login: Login successful for ${result.student?.name}');
        
        // Check if semester is missing and try to fetch from Supabase
        if (_currentUser!.semester.isEmpty || _currentUser!.semester == "N/A") {
          try {
             final supabaseData = await SupabaseService().lookupStudent(_currentUser!.enrollment);
             if (supabaseData != null && supabaseData['semester'] != null) {
               final storedSemester = supabaseData['semester'].toString();
               if (storedSemester.isNotEmpty) {
                 debugPrint('AuthService: Restoring semester from Supabase: $storedSemester');
                 _currentUser = _currentUser!.copyWith(semester: storedSemester);
               }
             }
          } catch (e) {
            debugPrint('AuthService: Failed to restore semester from Supabase: $e');
          }
        }
        
        // Store session for later use
        if (_sessionCookie != null) {
          await _storage.write(key: AppConstants.sessionKey, value: _sessionCookie);
        }
        await _storage.write(key: AppConstants.userDataKey, value: jsonEncode(_currentUser!.toJson()));
        
        // Cache user profile for offline access
        await _cacheService.cacheUserProfile(_currentUser!.toJson());
        
        // Track user stats in Supabase (background)
        SupabaseService().saveUser(_currentUser!.toJson());

        _isOffline = false;
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result.error ?? 'Login failed. Please check your credentials.';
        debugPrint('AuthService.login: Login failed - $_error');
      }
    } catch (e, stackTrace) {
      debugPrint('AuthService.login: Exception - $e');
      debugPrint('AuthService.login: Stack trace - $stackTrace');
      _error = 'Connection error: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Check for existing valid session
  Future<bool> checkSession() async {
    try {
      final userData = await _storage.read(key: AppConstants.userDataKey);
      
      if (userData != null) {
        _currentUser = Student.fromJson(jsonDecode(userData));
        notifyListeners();
        
        // Restore session cookie
        final sessionCookie = await _storage.read(key: AppConstants.sessionKey);
        if (sessionCookie != null) {
          _gmsService.setSession(sessionCookie);
          _sessionCookie = sessionCookie;
        }

        // Verify session is still valid
        final isValid = await _gmsService.isSessionValid();
        if (!isValid) {
          // Session expired, but try to load cached user for offline viewing
          final cachedProfile = await _cacheService.getCachedUserProfile();
          if (cachedProfile != null) {
            _currentUser = Student.fromJson(cachedProfile);
            _isOffline = true;
            notifyListeners();
            return true; // Allow offline access with cached data
          }
          // No cached data, clear session
          await _storage.delete(key: AppConstants.sessionKey);
          await _storage.delete(key: AppConstants.userDataKey);
          _currentUser = null;
          notifyListeners();
          return false;
        }
        
        _isOffline = false;
        return true;
      }
      
      // No stored session, try loading from cache for offline access
      final cachedProfile = await _cacheService.getCachedUserProfile();
      if (cachedProfile != null) {
        _currentUser = Student.fromJson(cachedProfile);
        _isOffline = true;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Session check error: $e');
      // Try cached profile as fallback
      try {
        final cachedProfile = await _cacheService.getCachedUserProfile();
        if (cachedProfile != null) {
          _currentUser = Student.fromJson(cachedProfile);
          _isOffline = true;
          notifyListeners();
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  /// Login with demo mode - no GMS credentials required
  Future<bool> loginWithDemoMode() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Create demo student
      _currentUser = Student.demo();
      _isDemoMode = true;
      _isOffline = false;
      _sessionCookie = 'demo_session';
      
      debugPrint('AuthService: Demo mode login successful');
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to start demo mode: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout - clear all stored data
  Future<void> logout() async {
    _currentUser = null;
    _sessionCookie = null;
    _captchaImageBytes = null;
    _hasCaptcha = false;
    _isDemoMode = false;
    _gmsService.clearSession();
    
    await _storage.delete(key: AppConstants.sessionKey);
    await _storage.delete(key: AppConstants.userDataKey);
    
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Update user profile (for manual edits like branch, semester, section)
  Future<void> updateUser(Student updatedUser) async {
    _currentUser = updatedUser;
    
    // Persist updates to storage
    await _storage.write(key: AppConstants.userDataKey, value: jsonEncode(updatedUser.toJson()));
    
    // Update cache as well
    await _cacheService.cacheUserProfile(updatedUser.toJson());

    // Sync to Supabase
    try {
      await SupabaseService().saveUser(updatedUser.toJson());
    } catch (e) {
      debugPrint('Error syncing user update to Supabase: $e');
    }
    
    notifyListeners();
  }
}
