import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';
import '../models/city_suggestion.dart';
import '../config/api_config.dart';

class WeatherService {
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
  static const String geocodingUrl = 'https://api.openweathermap.org/geo/1.0/direct';

  Future<WeatherData?> getWeatherByCityName(String cityName) async {
    try {
      final url = Uri.parse(
        '$baseUrl?q=$cityName&appid=${ApiConfig.apiKey}&units=metric',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return WeatherData.fromJson(jsonData);
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching weather: $e');
    }
  }

  Future<List<CitySuggestion>> getCitySuggestions(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      final url = Uri.parse(
        '$geocodingUrl?q=$query&limit=5&appid=${ApiConfig.apiKey}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData
            .map((json) => CitySuggestion.fromJson(json))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}

