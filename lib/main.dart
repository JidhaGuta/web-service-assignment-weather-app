import 'dart:async';
import 'package:flutter/material.dart';
import 'models/weather_data.dart';
import 'models/city_suggestion.dart';
import 'services/weather_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'weather_app',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const WeatherScreen(),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _cityController = TextEditingController();
  final WeatherService _weatherService = WeatherService();
  final FocusNode _searchFocusNode = FocusNode();
  WeatherData? _weatherData;
  bool _isLoading = false;
  String? _errorMessage;
  List<CitySuggestion> _suggestions = [];
  bool _showSuggestions = false;
  Timer? _debounceTimer;

  Future<void> _fetchWeather() async {
    if (_cityController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a city name';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _weatherData = null;
      _showSuggestions = false;
    });

    try {
      final weather = await _weatherService.getWeatherByCityName(
        _cityController.text.trim(),
      );
      setState(() {
        _weatherData = weather;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'City not found. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    
    if (value.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _fetchSuggestions(value);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    final suggestions = await _weatherService.getCitySuggestions(query);
    setState(() {
      _suggestions = suggestions;
      _showSuggestions = suggestions.isNotEmpty;
    });
  }

  void _selectCity(CitySuggestion city) {
    setState(() {
      _cityController.text = city.name;
      _showSuggestions = false;
      _suggestions = [];
    });
    _searchFocusNode.unfocus();
    _fetchWeather();
  }

  @override
  void dispose() {
    _cityController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade400,
              Colors.blue.shade600,
              Colors.purple.shade600,
            ],
          ),
        ),
        child: GestureDetector(
          onTap: () {
            _searchFocusNode.unfocus();
            setState(() {
              _showSuggestions = false;
            });
          },
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // App Title
                const Text(
                  'weather_app',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Get real-time weather information',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),
                // Search Input with Suggestions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _cityController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Enter city name (e.g., London, New York)',
                          prefixIcon: const Icon(Icons.search, color: Colors.blue),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _cityController.clear();
                              setState(() {
                                _weatherData = null;
                                _errorMessage = null;
                                _suggestions = [];
                                _showSuggestions = false;
                              });
                            },
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                        ),
                        onChanged: _onSearchChanged,
                        onSubmitted: (_) => _fetchWeather(),
                        onTap: () {
                          if (_suggestions.isNotEmpty) {
                            setState(() {
                              _showSuggestions = true;
                            });
                          }
                        },
                      ),
                    ),
                    // Suggestions List
                    if (_showSuggestions && _suggestions.isNotEmpty)
                      GestureDetector(
                        onTap: () {}, // Prevent parent GestureDetector from closing suggestions
                        child: Container(
                          margin: const EdgeInsets.only(top: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _suggestions.length,
                            itemBuilder: (context, index) {
                              final city = _suggestions[index];
                              return InkWell(
                                onTap: () => _selectCity(city),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_city,
                                        color: Colors.blue.shade300,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          city.displayName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                // Search Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _fetchWeather,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 5,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        )
                      : const Text(
                          'Get Weather',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 30),
                // Error Message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Weather Data Display
                if (_weatherData != null) ...[
                  const SizedBox(height: 20),
                  _buildWeatherCard(),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildWeatherCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // City and Country
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 28),
              const SizedBox(width: 8),
              Text(
                '${_weatherData!.cityName}, ${_weatherData!.country}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          // Temperature
          Text(
            '${_weatherData!.temperature.toStringAsFixed(1)}°C',
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 10),
          // Description
          Text(
            _weatherData!.description.toUpperCase(),
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 20),
          // Weather Details Grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDetailItem(
                Icons.thermostat,
                'Feels Like',
                '${_weatherData!.feelsLike.toStringAsFixed(1)}°C',
                Colors.orange,
              ),
              _buildDetailItem(
                Icons.water_drop,
                'Humidity',
                '${_weatherData!.humidity}%',
                Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailItem(
            Icons.air,
            'Wind Speed',
            '${_weatherData!.windSpeed.toStringAsFixed(1)} m/s',
            Colors.green,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    IconData icon,
    String label,
    String value,
    Color color, {
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

