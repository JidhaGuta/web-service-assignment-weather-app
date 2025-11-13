# Weather App

A beautiful Flutter application that fetches and displays weather information from OpenWeatherMap API.

## Features

- Search weather by city name
- Beautiful gradient UI design
- Real-time weather data display
- Shows temperature, feels like, humidity, description, and wind speed
- Error handling for invalid city names

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK

### Installation

1. Clone or download this project
2. Navigate to the project directory
3. Install dependencies:
   ```bash
   flutter pub get
   ```

### Running the App

```bash
flutter run
```

## Usage

1. Enter a city name in the search field (e.g., "London", "New York", "Tokyo")
2. Tap the "Get Weather" button or press Enter
3. View the weather information displayed in a beautiful card

## API Key

The OpenWeatherMap API key is configured in `lib/config/api_config.dart`.

## Project Structure

```
lib/
├── main.dart                 # Main app entry point and UI
├── models/
│   └── weather_data.dart    # Weather data model
├── services/
│   └── weather_service.dart # API service for fetching weather
└── config/
    └── api_config.dart      # API configuration
```

## Dependencies

- `http`: For making HTTP requests to the OpenWeatherMap API
- `flutter`: Flutter SDK

## Notes

- The app uses metric units (Celsius, m/s)
- City names should be entered in English
- Internet connection is required to fetch weather data

