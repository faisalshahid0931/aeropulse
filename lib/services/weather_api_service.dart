import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherApiService {
  Future<WeatherModel> fetchWeather(double lat, double lon) async {
    final String forecastUrl =
        'https://api.open-meteo.com/v1/forecast?'
        'latitude=$lat&longitude=$lon'
        '&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,surface_pressure,wind_speed_10m,uv_index'
        '&hourly=temperature_2m,weather_code'
        '&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset'
        '&timezone=auto';

    final String airQualityUrl =
        'https://air-quality-api.open-meteo.com/v1/air-quality?'
        'latitude=$lat&longitude=$lon'
        '&current=us_aqi'
        '&timezone=auto';

    final forecastResponse = await http.get(Uri.parse(forecastUrl));
    final airQualityResponse = await http.get(Uri.parse(airQualityUrl));

    if (forecastResponse.statusCode == 200) {
      final forecastData = jsonDecode(forecastResponse.body);
      int usAqi = 0;

      if (airQualityResponse.statusCode == 200) {
        final aqData = jsonDecode(airQualityResponse.body);
        usAqi = (aqData['current']?['us_aqi'] as num?)?.toInt() ?? 0;
      }

      return WeatherModel.fromJson(forecastData, usAqi);
    } else {
      throw Exception('Failed to fetch weather data from Open-Meteo');
    }
  }

  Future<List<Map<String, dynamic>>> searchCity(String cityName) async {
    final String url =
        'https://geocoding-api.open-meteo.com/v1/search?name=$cityName&count=5&language=en&format=json';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['results'] != null) {
        return List<Map<String, dynamic>>.from(data['results']);
      }
    }
    return [];
  }
}