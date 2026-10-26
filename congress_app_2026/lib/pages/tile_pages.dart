import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'schedule_page.dart';

/// Decides which page each grid tile opens. Add a case for any tile that gets its own page.
Widget pageFor(String title) {
  final name = title.toLowerCase();

  // "contains" so tiles like "Creek Schedule" still match.
  if (name.contains('weather')) return const WeatherPage();
  if (name.contains('schedule')) return const SchedulePage();

  return TilePage(title: title);
}

/// Generic page used by tiles that don't have their own page yet.
class TilePage extends StatelessWidget {
  const TilePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar automatically shows a back arrow because this page was pushed
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to home'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// WEATHER PAGE
// ---------------------------------------------------------------------------
const double kLatitude = 39.6302;
const double kLongitude = -104.8823;

// High-contrast colors.
const Color _bg = Color(0xFF0D1B2A);
const Color _fg = Colors.white;
const Color _accent = Color(0xFFFFD60A);

/// Simple data holder for the current weather.
class WeatherInfo {
  const WeatherInfo({
    required this.temperatureF,
    required this.code,
    required this.windMph,
  });

  final int temperatureF;
  final int code;
  final int windMph;

  String get description {
    if (code == 0) return 'Sunny and clear';
    if (code == 1 || code == 2) return 'Partly cloudy';
    if (code == 3) return 'Cloudy';
    if (code == 45 || code == 48) return 'Foggy';
    if (code >= 51 && code <= 57) return 'Light rain';
    if (code >= 61 && code <= 67) return 'Rainy';
    if (code >= 71 && code <= 77) return 'Snowy';
    if (code >= 80 && code <= 82) return 'Rain showers';
    if (code == 85 || code == 86) return 'Snow showers';
    if (code >= 95) return 'Thunderstorm';
    return 'Unknown weather';
  }

  IconData get icon {
    if (code == 0) return Icons.wb_sunny;
    if (code == 1 || code == 2) return Icons.wb_cloudy_outlined;
    if (code == 3) return Icons.cloud;
    if (code == 45 || code == 48) return Icons.foggy;
    if (code >= 51 && code <= 67) return Icons.umbrella;
    if (code >= 71 && code <= 77) return Icons.ac_unit;
    if (code >= 80 && code <= 82) return Icons.grain;
    if (code == 85 || code == 86) return Icons.ac_unit;
    if (code >= 95) return Icons.thunderstorm;
    return Icons.help_outline;
  }

  /// Plain-language tip about what to wear or bring.
  String get tip {
    if (code >= 95) return 'Stay inside and stay safe.';
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
      return 'Bring an umbrella or a raincoat.';
    }
    if ((code >= 71 && code <= 77) || code == 85 || code == 86) {
      return 'Wear a warm coat, hat, and gloves.';
    }
    if (temperatureF <= 40) return 'It is cold. Wear a warm coat.';
    if (temperatureF <= 60) return 'It is cool. Wear a jacket.';
    if (temperatureF >= 85) return 'It is hot. Drink water.';
    return 'A nice day to go outside.';
  }

  String get spokenSummary =>
      'It is $temperatureF degrees. $description. $tip';
}

Future<WeatherInfo> fetchWeather() async {
  final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
    'latitude': '$kLatitude',
    'longitude': '$kLongitude',
    'current': 'temperature_2m,weather_code,wind_speed_10m',
    'temperature_unit': 'fahrenheit',
    'wind_speed_unit': 'mph',
  });

  final response = await http.get(uri).timeout(const Duration(seconds: 10));
  if (response.statusCode != 200) {
    throw Exception('Weather service error ${response.statusCode}');
  }

  final current = jsonDecode(response.body)['current'] as Map<String, dynamic>;
  return WeatherInfo(
    temperatureF: (current['temperature_2m'] as num).round(),
    code: (current['weather_code'] as num).toInt(),
    windMph: (current['wind_speed_10m'] as num).round(),
  );
}

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  late Future<WeatherInfo> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchWeather();
  }

  void _refresh() {
    setState(() {
      _future = fetchWeather();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Weather', style: TextStyle(fontSize: 28)),
        backgroundColor: _bg,
        foregroundColor: _fg,
        toolbarHeight: 72,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: FutureBuilder<WeatherInfo>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const _LoadingView();
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return const _ErrorView();
                    }
                    return _WeatherView(info: snapshot.data!);
                  },
                ),
              ),
              const SizedBox(height: 16),
              _BigButton(
                label: 'Refresh',
                icon: Icons.refresh,
                onPressed: _refresh,
              ),
              const SizedBox(height: 16),
              _BigButton(
                label: 'Back to home',
                icon: Icons.home,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeatherView extends StatelessWidget {
  const _WeatherView({required this.info});

  final WeatherInfo info;

  @override
  Widget build(BuildContext context) {
    // One spoken summary for screen readers instead of many small pieces.
    return Semantics(
      label: info.spokenSummary,
      liveRegion: true,
      child: ExcludeSemantics(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(info.icon, size: 140, color: _accent),
              const SizedBox(height: 16),
              Text(
                '${info.temperatureF}°',
                style: const TextStyle(
                  fontSize: 96,
                  fontWeight: FontWeight.bold,
                  color: _fg,
                ),
              ),
              Text(
                info.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  color: _fg,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  info.tip,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading the weather',
      liveRegion: true,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(strokeWidth: 8, color: _accent),
            ),
            SizedBox(height: 24),
            Text(
              'Loading...',
              style: TextStyle(fontSize: 32, color: _fg),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Could not load the weather. Check the internet and press Refresh.',
      liveRegion: true,
      child: const ExcludeSemantics(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off, size: 120, color: _accent),
              SizedBox(height: 16),
              Text(
                'Could not get the weather.\nPress Refresh to try again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, color: _fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Large, high-contrast button with an icon and a text label.
class _BigButton extends StatelessWidget {
  const _BigButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 36),
        label: Text(label, style: const TextStyle(fontSize: 28)),
        style: FilledButton.styleFrom(
          backgroundColor: _fg,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}