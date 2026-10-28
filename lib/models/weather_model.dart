import 'package:flutter/material.dart';

class DailyForecast {
  final String date;
  final double maxTemp;
  final double minTemp;
  final int weatherCode;

  DailyForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.weatherCode,
  });

  String get dayName {
    final DateTime parsed = DateTime.tryParse(date) ?? DateTime.now();
    final List<String> weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return weekdays[parsed.weekday - 1];
  }

  String get description => WeatherModel.getWmoDescription(weatherCode);
  IconData get icon => WeatherModel.getWmoIcon(weatherCode);
  Color get color => WeatherModel.getWmoColor(weatherCode);
}

class HourlyForecast {
  final String time;
  final double temp;
  final int weatherCode;

  HourlyForecast({
    required this.time,
    required this.temp,
    required this.weatherCode,
  });

  String get formattedTime {
    final DateTime parsed = DateTime.tryParse(time) ?? DateTime.now();
    final hour = parsed.hour;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour % 12 == 0 ? 12 : hour % 12;
    return "$formattedHour $ampm";
  }

  IconData get icon => WeatherModel.getWmoIcon(weatherCode);
}

class WeatherModel {
  final double temperature;
  final double feelsLike;
  final double windspeed;
  final int humidity;
  final double pressure;
  final double uvIndex;
  final int aqi;
  final String sunrise;
  final String sunset;
  final int weatherCode;
  final List<HourlyForecast> hourly;
  final List<DailyForecast> daily;

  WeatherModel({
    required this.temperature,
    required this.feelsLike,
    required this.windspeed,
    required this.humidity,
    required this.pressure,
    required this.uvIndex,
    required this.aqi,
    required this.sunrise,
    required this.sunset,
    required this.weatherCode,
    required this.hourly,
    required this.daily,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json, int usAqi) {
    final current = json['current'] ?? {};
    
    // Hourly
    final hourlyJson = json['hourly'] ?? {};
    final List<String> times = List<String>.from(hourlyJson['time'] ?? []);
    final List temps = hourlyJson['temperature_2m'] ?? [];
    final List codes = hourlyJson['weather_code'] ?? [];

    final now = DateTime.now();
    int startIndex = 0;
    for (int i = 0; i < times.length; i++) {
      final dt = DateTime.tryParse(times[i]);
      if (dt != null && (dt.isAfter(now) || dt.hour == now.hour)) {
        startIndex = i;
        break;
      }
    }

    List<HourlyForecast> hourlyList = [];
    for (int i = startIndex; i < times.length && hourlyList.length < 24; i++) {
      hourlyList.add(HourlyForecast(
        time: times[i],
        temp: (temps[i] as num).toDouble(),
        weatherCode: (codes[i] as num).toInt(),
      ));
    }

    // Daily
    final dailyJson = json['daily'] ?? {};
    final List<String> dDates = List<String>.from(dailyJson['time'] ?? []);
    final List dMax = dailyJson['temperature_2m_max'] ?? [];
    final List dMin = dailyJson['temperature_2m_min'] ?? [];
    final List dCodes = dailyJson['weather_code'] ?? [];
    final List dSunrises = List<String>.from(dailyJson['sunrise'] ?? []);
    final List dSunsets = List<String>.from(dailyJson['sunset'] ?? []);

    List<DailyForecast> dailyList = [];
    for (int i = 0; i < dDates.length && i < 7; i++) {
      dailyList.add(DailyForecast(
        date: dDates[i],
        maxTemp: (dMax[i] as num).toDouble(),
        minTemp: (dMin[i] as num).toDouble(),
        weatherCode: (dCodes[i] as num).toInt(),
      ));
    }

    String formatTimeString(String isoTime) {
      final dt = DateTime.tryParse(isoTime);
      if (dt == null) return "--:--";
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return "$hour:$minute $ampm";
    }

    return WeatherModel(
      temperature: (current['temperature_2m'] as num).toDouble(),
      feelsLike: (current['apparent_temperature'] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] as num).toInt(),
      pressure: (current['surface_pressure'] as num).toDouble(),
      uvIndex: (current['uv_index'] as num?)?.toDouble() ?? 0.0,
      aqi: usAqi,
      sunrise: dSunrises.isNotEmpty ? formatTimeString(dSunrises[0]) : "--:--",
      sunset: dSunsets.isNotEmpty ? formatTimeString(dSunsets[0]) : "--:--",
      windspeed: (current['wind_speed_10m'] as num).toDouble(),
      weatherCode: (current['weather_code'] as num).toInt(),
      hourly: hourlyList,
      daily: dailyList,
    );
  }

  String get aqiStatus {
    if (aqi <= 50) return "Good";
    if (aqi <= 100) return "Moderate";
    if (aqi <= 150) return "Unhealthy (Sensitive)";
    if (aqi <= 200) return "Unhealthy";
    return "Hazardous";
  }

  Color get aqiColor {
    if (aqi <= 50) return Colors.greenAccent;
    if (aqi <= 100) return Colors.yellowAccent;
    if (aqi <= 150) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  String get weatherDescription => getWmoDescription(weatherCode);
  IconData get weatherIcon => getWmoIcon(weatherCode);
  Color get weatherColor => getWmoColor(weatherCode);

  static String getWmoDescription(int code) {
    switch (code) {
      case 0:
        return "Clear Sky";
      case 1:
      case 2:
        return "Partly Cloudy";
      case 3:
        return "Overcast";
      case 45:
      case 48:
        return "Foggy";
      case 51:
      case 53:
      case 55:
      case 61:
      case 63:
        return "Rain Showers";
      case 71:
      case 73:
      case 75:
        return "Snowfall";
      default:
        return "Fair Weather";
    }
  }

  static IconData getWmoIcon(int code) {
    switch (code) {
      case 0:
        return Icons.wb_sunny_rounded;
      case 1:
      case 2:
      case 3:
        return Icons.cloud_queue_rounded;
      case 45:
      case 48:
        return Icons.blur_on_rounded;
      case 51:
      case 53:
      case 55:
      case 61:
      case 63:
        return Icons.grain_rounded;
      case 71:
      case 73:
      case 75:
        return Icons.ac_unit_rounded;
      default:
        return Icons.wb_sunny_rounded;
    }
  }

  static Color getWmoColor(int code) {
    switch (code) {
      case 0:
        return Colors.amberAccent;
      case 1:
      case 2:
      case 3:
        return Colors.cyanAccent;
      case 51:
      case 53:
      case 61:
        return Colors.blueAccent;
      default:
        return Colors.amberAccent;
    }
  }

  List<Color> get backgroundGradient {
    switch (weatherCode) {
      case 0:
        return const [
          Color(0xFF0F2027),
          Color(0xFF203A43),
          Color(0xFF2C5364),
        ];
      case 1:
      case 2:
      case 3:
        return const [
          Color(0xFF1F1C2C),
          Color(0xFF928DAB),
        ];
      case 51:
      case 53:
      case 55:
      case 61:
      case 63:
        return const [
          Color(0xFF141E30),
          Color(0xFF243B55),
        ];
      default:
        return const [
          Color(0xFF0F2027),
          Color(0xFF203A43),
          Color(0xFF2C5364),
        ];
    }
  }
}