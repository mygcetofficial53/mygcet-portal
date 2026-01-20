class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://localhost:5000/api';
  static const String loginEndpoint = '$baseUrl/login';
  static const String captchaEndpoint = '$baseUrl/captcha';
  static const String dashboardEndpoint = '$baseUrl/dashboard';
  static const String attendanceEndpoint = '$baseUrl/attendance';
  static const String materialsEndpoint = '$baseUrl/materials';
  static const String quizEndpoint = '$baseUrl/quiz';
  static const String libraryEndpoint = '$baseUrl/library';
  static const String calendarEndpoint = '$baseUrl/calendar';
  
  // GMS Portal URLs
  static const String gmsBaseUrl = 'http://202.129.240.148:8080/GIS';
  static const String gmsLoginUrl = '$gmsBaseUrl/StudentLogin.jsp';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String sessionKey = 'session_id';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'app_theme';
  
  // Timeouts
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;
  
  // App Info
  static const String appName = 'MyGCET';
  static const String appVersion = '1.0.0+2002';
}
