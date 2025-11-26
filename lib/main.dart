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
      title: 'Weather Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Inter',
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

class _WeatherScreenState extends State<WeatherScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _cityController = TextEditingController();
  final WeatherService _weatherService = WeatherService();
  final FocusNode _searchFocusNode = FocusNode();
  WeatherData? _weatherData;
  bool _isLoading = false;
  String? _errorMessage;
  List<CitySuggestion> _suggestions = [];
  bool _showSuggestions = false;
  Timer? _debounceTimer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
  }

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
      _animationController.reset();
      _animationController.forward();
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

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
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

  Color _getWeatherColor() {
    if (_weatherData == null) return Colors.blue.shade400;
    
    final temp = _weatherData!.temperature;
    if (temp < 0) return Colors.blue.shade800;
    if (temp < 10) return Colors.blue.shade600;
    if (temp < 20) return Colors.blue.shade400;
    if (temp < 30) return Colors.orange.shade400;
    return Colors.red.shade400;
  }

  IconData _getWeatherIcon() {
    final desc = _weatherData?.description.toLowerCase() ?? '';
    if (desc.contains('rain')) return Icons.umbrella;
    if (desc.contains('cloud')) return Icons.cloud;
    if (desc.contains('snow')) return Icons.ac_unit;
    if (desc.contains('thunderstorm')) return Icons.flash_on;
    return Icons.wb_sunny;
  }

  @override
  void dispose() {
    _cityController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weatherColor = _getWeatherColor();

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 1000),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              weatherColor.withOpacity(0.8),
              weatherColor,
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
                  const SizedBox(height: 20),
                  // App Title with improved typography
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud, color: Colors.white, size: 32),
                            SizedBox(width: 8),
                            Text(
                              'Weather Pro',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _weatherData != null 
                              ? 'Current weather in ${_weatherData!.cityName}'
                              : 'Get real-time weather information',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Search Section
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Search Input with enhanced styling
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _cityController,
                              focusNode: _searchFocusNode,
                              decoration: InputDecoration(
                                hintText: 'Search city... (e.g., London, Tokyo)',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 16,
                                ),
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: weatherColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.search, color: weatherColor),
                                ),
                                suffixIcon: _cityController.text.isNotEmpty
                                    ? IconButton(
                                        icon: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.clear, 
                                            color: Colors.grey.shade600,
                                            size: 20,
                                          ),
                                        ),
                                        onPressed: () {
                                          _cityController.clear();
                                          setState(() {
                                            _weatherData = null;
                                            _errorMessage = null;
                                            _suggestions = [];
                                            _showSuggestions = false;
                                          });
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
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
                          
                          // Enhanced Suggestions List
                          if (_showSuggestions && _suggestions.isNotEmpty)
                            GestureDetector(
                              onTap: () {},
                              child: Container(
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                constraints: const BoxConstraints(maxHeight: 200),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _suggestions.length,
                                  itemBuilder: (context, index) {
                                    final city = _suggestions[index];
                                    return Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _selectCity(city),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 36,
                                                height: 36,
                                                decoration: BoxDecoration(
                                                  color: weatherColor.withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.location_on,
                                                  color: weatherColor,
                                                  size: 18,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      city.name,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                    if (city.country.isNotEmpty)
                                                      Text(
                                                        city.country,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey.shade600,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                color: Colors.grey.shade400,
                                                size: 16,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Enhanced Search Button
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: weatherColor.withOpacity(0.4),
                              blurRadius: _isLoading ? 15 : 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _fetchWeather,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: weatherColor,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(weatherColor),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Get Weather',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward, size: 20),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Enhanced Error Message
                  if (_errorMessage != null)
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red.shade100),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.error_outline, 
                                  color: Colors.red.shade700,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Location not found',
                                      style: TextStyle(
                                        color: Colors.red.shade800,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        color: Colors.red.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  
                  // Enhanced Weather Data Display
                  if (_weatherData != null) ...[
                    const SizedBox(height: 30),
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildWeatherCard(weatherColor),
                      ),
                    ),
                  ],
                  
                  // Empty State
                  if (_weatherData == null && !_isLoading && _errorMessage == null)
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          margin: const EdgeInsets.only(top: 60),
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 80,
                                color: Colors.white.withOpacity(0.5),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Search for a city to see weather information',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherCard(Color weatherColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          // City and Country with improved layout
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: weatherColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.location_on, 
                  color: weatherColor, 
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _weatherData!.cityName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    _weatherData!.country,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          
          // Temperature with weather icon
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      weatherColor.withOpacity(0.1),
                      weatherColor.withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
              Column(
                children: [
                  Icon(
                    _getWeatherIcon(),
                    size: 64,
                    color: weatherColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${_weatherData!.temperature.toStringAsFixed(1)}°C',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: weatherColor,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Description with improved styling
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: weatherColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _weatherData!.description.toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                color: weatherColor,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 30),
          
          const Divider(height: 1, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          
          // Enhanced Weather Details Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildDetailCard(
                Icons.thermostat,
                'Feels Like',
                '${_weatherData!.feelsLike.toStringAsFixed(1)}°C',
                Colors.orange,
              ),
              _buildDetailCard(
                Icons.water_drop,
                'Humidity',
                '${_weatherData!.humidity}%',
                Colors.blue,
              ),
              _buildDetailCard(
                Icons.air,
                'Wind Speed',
                '${_weatherData!.windSpeed.toStringAsFixed(1)} m/s',
                Colors.green,
              ),
              _buildDetailCard(
                Icons.compress,
                'Pressure',
                '${_weatherData!.pressure ?? 1013} hPa',
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}