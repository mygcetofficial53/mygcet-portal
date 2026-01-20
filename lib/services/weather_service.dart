import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class WeatherData {
  final double temperature;
  final int iconNum;
  final bool isDay; // Added isDay
  final String condition;
  
  WeatherData({
    required this.temperature,
    required this.iconNum,
    required this.isDay,
    required this.condition,
  });

  String get animationPath {
    // Legacy support for Lottie if needed, but we use WeatherVisuals now.
    return 'assets/animations/weather/sunny.json';
  }
}

class WeatherService extends ChangeNotifier {
  WeatherData? _currentWeather;
  bool _isLoading = false;

  WeatherData? get currentWeather => _currentWeather;
  bool get isLoading => _isLoading;

  // Anand, Gujarat Coordinates
  static const double lat = 22.56001;
  static const double long = 72.91982;

  Future<void> fetchWeather() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Open-Meteo API (No Key Required)
      final url = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latiogtude=$lat&longitude=$long&current_weather=true');
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        debugPrint('Weather API RAW Response: ${response.body}');
        final data = json.decode(response.body);
        
        if (data['current_weather'] != null) {
          final current = data['current_weather'];
          
          final temp = current['temperature'];
          final wmoCode = current['weathercode'];
          final isDayInt = current['is_day']; // 1 = Day, 0 = Night
          
          // Map WMO Code to our Visuals iconNum
          final mappedIcon = _mapWmoToIconNum(wmoCode);
          final isDay = isDayInt == 1;

          _currentWeather = WeatherData(
            temperature: (temp is num) ? temp.toDouble() : 0.0,
            iconNum: mappedIcon,
            isDay: isDay,
            condition: _getWmoDescription(wmoCode),
          );
        }
      } else {
        debugPrint('Weather API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Weather Fetch Exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper to map Open-Meteo WMO codes to our existing Visuals system
  // Visuals expects: 2=Sunny, 6-8=Cloudy, 9=Fog, 10-13=Rain, 14=Storm
  int _mapWmoToIconNum(int code) {
    if (code == 0) return 2; // Clear Sky -> Sunny
    if (code >= 1 && code <= 3) return 6; // Partly Cloudy -> Cloudy
    if (code == 45 || code == 48) return 9; // Fog
    if (code >= 51 && code <= 67) return 10; // Drizzle/Rain -> Rain
    if (code >= 80 && code <= 82) return 10; // Showers -> Rain
    if (code >= 95) return 14; // Thunderstorm -> Storm
    return 2; // Default to sunny
  }

  String _getWmoDescription(int code) {
    switch (code) {
      case 0: return 'Clear Sky';
      case 1: return 'Mainly Clear';
      case 2: return 'Partly Cloudy';
      case 3: return 'Overcast';
      case 45: return 'Fog';
      case 48: return 'Depositing Rime Fog';
      case 51: return 'Light Drizzle';
      case 53: return 'Moderate Drizzle';
      case 55: return 'Dense Drizzle';
      case 61: return 'Slight Rain';
      case 63: return 'Moderate Rain';
      case 65: return 'Heavy Rain';
      case 80: return 'Slight Showers';
      case 81: return 'Moderate Showers';
      case 82: return 'Violent Showers';
      case 95: return 'Thunderstorm';
      default: return 'Weather';
    }
  }
}
