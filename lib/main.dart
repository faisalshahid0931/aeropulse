import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/weather_api_service.dart';
import 'models/weather_model.dart';

void main() {
  runApp(const MasterpieceWeatherApp());
}

class MasterpieceWeatherApp extends StatelessWidget {
  const MasterpieceWeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AeroPulse',
      theme: ThemeData(fontFamily: 'Roboto', brightness: Brightness.dark),
      home: const SplashScreen(),
    );
  }
}

// -----------------------------------------------------------------------------
// SPLASH SCREEN
// -----------------------------------------------------------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const WeatherHomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F2027),
                  Color(0xFF203A43),
                  Color(0xFF2C5364),
                ],
              ),
            ),
          ),
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.cyanAccent.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withValues(alpha: 0.12),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: const Icon(
                    Icons.air_rounded,
                    size: 72,
                    color: Colors.cyanAccent,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "AeroPulse",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Atmospheric Intelligence",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white54,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.cyanAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// WEATHER HOME SCREEN
// -----------------------------------------------------------------------------
class WeatherHomeScreen extends StatefulWidget {
  const WeatherHomeScreen({super.key});

  @override
  State<WeatherHomeScreen> createState() => _WeatherHomeScreenState();
}

class _WeatherHomeScreenState extends State<WeatherHomeScreen> {
  final WeatherApiService _apiService = WeatherApiService();
  late Future<WeatherModel> _weatherFuture;

  String _selectedCity = "Peshawar, PK";
  double _currentLat = 34.0151;
  double _currentLon = 71.5249;
  bool _isCelsius = true;

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  final List<Map<String, dynamic>> _presetCities = [
    {"name": "Peshawar, PK", "lat": 34.0151, "lon": 71.5249},
    {"name": "Islamabad, PK", "lat": 33.6844, "lon": 73.0479},
    {"name": "Lahore, PK", "lat": 31.5204, "lon": 74.3587},
    {"name": "Karachi, PK", "lat": 24.8607, "lon": 67.0011},
    {"name": "London, UK", "lat": 51.5074, "lon": -0.1278},
    {"name": "New York, US", "lat": 40.7128, "lon": -74.0060},
  ];

  @override
  void initState() {
    super.initState();
    _weatherFuture = _apiService.fetchWeather(_currentLat, _currentLon);
    _loadSavedPreferences();
  }

  Future<void> _loadSavedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCity = prefs.getString('saved_city_name');

    if (savedCity != null) {
      setState(() {
        _selectedCity = savedCity;
        _currentLat = prefs.getDouble('saved_city_lat') ?? 34.0151;
        _currentLon = prefs.getDouble('saved_city_lon') ?? 71.5249;
        _isCelsius = prefs.getBool('is_celsius') ?? true;
      });
      _refreshWeatherData();
    }
  }

  Future<void> _saveLocationPreference(String name, double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_city_name', name);
    await prefs.setDouble('saved_city_lat', lat);
    await prefs.setDouble('saved_city_lon', lon);
  }

  Future<void> _toggleUnitPreference() async {
    final newUnit = !_isCelsius;
    setState(() {
      _isCelsius = newUnit;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_celsius', newUnit);
  }

  double _convertTemp(double celsiusTemp) {
    if (_isCelsius) return celsiusTemp;
    return (celsiusTemp * 9 / 5) + 32;
  }

  Future<void> _refreshWeatherData() async {
    setState(() {
      _weatherFuture = _apiService.fetchWeather(_currentLat, _currentLon);
    });
    await _weatherFuture;
  }

  void _selectCity(String cityName, double lat, double lon) {
    setState(() {
      _selectedCity = cityName;
      _currentLat = lat;
      _currentLon = lon;
    });
    _saveLocationPreference(cityName, lat, lon);
    _refreshWeatherData();
    Navigator.pop(context);
  }

  void _openSearchSheet() {
    _searchController.clear();
    _searchResults = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: const Color(0xFF0F2027).withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              border: Border.all(color: Colors.white12, width: 1.5),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Search city (e.g. Islamabad, London)...",
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.cyanAccent),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54),
                            onPressed: () {
                              _searchController.clear();
                              setModalState(() => _searchResults = []);
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) async {
                    if (val.trim().length > 2) {
                      setModalState(() => _isSearching = true);
                      final results = await _apiService.searchCity(val);
                      setModalState(() {
                        _searchResults = results;
                        _isSearching = false;
                      });
                    } else {
                      setModalState(() => _searchResults = []);
                    }
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  _searchResults.isNotEmpty ? "Search Results" : "Popular Cities",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _isSearching
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.cyanAccent),
                        )
                      : _searchResults.isNotEmpty
                          ? ListView.builder(
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final item = _searchResults[index];
                                final name = item['name'] ?? '';
                                final country = item['country'] ?? '';
                                final lat = (item['latitude'] as num).toDouble();
                                final lon = (item['longitude'] as num).toDouble();
                                final displayName =
                                    country.isNotEmpty ? "$name, $country" : name;

                                return ListTile(
                                  leading: const Icon(Icons.location_city, color: Colors.cyanAccent),
                                  title: Text(displayName, style: const TextStyle(color: Colors.white)),
                                  subtitle: Text("Lat: ${lat.toStringAsFixed(2)}, Lon: ${lon.toStringAsFixed(2)}",
                                      style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                  onTap: () => _selectCity(displayName, lat, lon),
                                );
                              },
                            )
                          : ListView.builder(
                              itemCount: _presetCities.length,
                              itemBuilder: (context, index) {
                                final city = _presetCities[index];
                                return ListTile(
                                  leading: const Icon(Icons.pin_drop_outlined, color: Colors.cyanAccent),
                                  title: Text(city['name'], style: const TextStyle(color: Colors.white)),
                                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
                                  onTap: () => _selectCity(
                                    city['name'],
                                    city['lat'],
                                    city['lon'],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WeatherModel>(
      future: _weatherFuture,
      builder: (context, snapshot) {
        List<Color> currentGradient = const [
          Color(0xFF0F2027),
          Color(0xFF203A43),
          Color(0xFF2C5364),
        ];

        if (snapshot.hasData) {
          currentGradient = snapshot.data!.backgroundGradient;
        }

        return Scaffold(
          body: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: currentGradient,
                  ),
                ),
              ),
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.cyanAccent.withValues(alpha: 0.15),
                  ),
                ),
              ),
              SafeArea(
                child: RefreshIndicator(
                  color: Colors.cyanAccent,
                  backgroundColor: const Color(0xFF0F2027),
                  onRefresh: _refreshWeatherData,
                  child: _buildBody(context, snapshot),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AsyncSnapshot<WeatherModel> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.cyanAccent),
      );
    } else if (snapshot.hasError) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Error loading weather:\n${snapshot.error}\n\nSwipe down to retry.",
                  style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      );
    } else if (snapshot.hasData) {
      final weather = snapshot.data!;

      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.cyanAccent, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          _selectedCity,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "Live Open-Meteo Feed",
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _toggleUnitPreference,
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Text(
                          _isCelsius ? "°C" : "°F",
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _openSearchSheet,
                      child: const GlassCard(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.search, color: Colors.white),
                      ),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 25),

            // Hero Weather Card
            Center(
              child: Column(
                children: [
                  Icon(
                    weather.weatherIcon,
                    size: 96,
                    color: weather.weatherColor,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "${_convertTemp(weather.temperature).round()}°",
                    style: const TextStyle(
                      fontSize: 84,
                      fontWeight: FontWeight.w200,
                      color: Colors.white,
                      letterSpacing: -2,
                    ),
                  ),
                  Text(
                    weather.weatherDescription,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Feels like ${_convertTemp(weather.feelsLike).round()}°",
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Air Quality Banner Card
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.air_outlined, color: weather.aqiColor, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Air Quality Index (AQI)",
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${weather.aqi} — ${weather.aqiStatus}",
                          style: TextStyle(
                            color: weather.aqiColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Metrics Grid 2x2
            Row(
              children: [
                Expanded(
                  child: MetricTile(
                    icon: Icons.water_drop_outlined,
                    title: "Humidity",
                    value: "${weather.humidity}%",
                    subtitle: "Real-time sensor",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricTile(
                    icon: Icons.air,
                    title: "Wind Speed",
                    value: "${weather.windspeed.round()} km/h",
                    subtitle: "Live reading",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MetricTile(
                    icon: Icons.speed,
                    title: "Pressure",
                    value: "${weather.pressure.round()} hPa",
                    subtitle: "Surface level",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricTile(
                    icon: Icons.wb_sunny_outlined,
                    title: "UV Index",
                    value: weather.uvIndex.toStringAsFixed(1),
                    subtitle: weather.uvIndex > 5 ? "High risk" : "Moderate",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Sunrise & Sunset Tile
            Row(
              children: [
                Expanded(
                  child: MetricTile(
                    icon: Icons.wb_twilight,
                    title: "Sunrise",
                    value: weather.sunrise,
                    subtitle: "Dawn time",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricTile(
                    icon: Icons.nights_stay_outlined,
                    title: "Sunset",
                    value: weather.sunset,
                    subtitle: "Dusk time",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // 24-Hour Forecast
            const Text(
              "24-Hour Forecast",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: weather.hourly.length,
                itemBuilder: (context, index) {
                  final item = weather.hourly[index];
                  return HourlyTile(
                    time: index == 0 ? "Now" : item.formattedTime,
                    temp: "${_convertTemp(item.temp).round()}°",
                    icon: item.icon,
                    isNow: index == 0,
                  );
                },
              ),
            ),
            const SizedBox(height: 30),

            // 7-Day Forecast
            const Text(
              "7-Day Forecast",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: weather.daily.length,
              itemBuilder: (context, index) {
                final day = weather.daily[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: 60,
                          child: Text(
                            index == 0 ? "Today" : day.dayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(day.icon, color: day.color, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              day.description,
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                        Text(
                          "${_convertTemp(day.maxTemp).round()}° / ${_convertTemp(day.minTemp).round()}°",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }
    return const SizedBox();
  }
}

// -----------------------------------------------------------------------------
// REUSABLE COMPONENTS
// -----------------------------------------------------------------------------

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const MetricTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.cyanAccent, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class HourlyTile extends StatelessWidget {
  final String time;
  final String temp;
  final IconData icon;
  final bool isNow;

  const HourlyTile({
    super.key,
    required this.time,
    required this.temp,
    required this.icon,
    this.isNow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              time,
              style: TextStyle(
                color: isNow ? Colors.cyanAccent : Colors.white60,
                fontWeight: isNow ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Icon(icon, color: isNow ? Colors.amberAccent : Colors.white, size: 22),
            const SizedBox(height: 8),
            Text(
              temp,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}