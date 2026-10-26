import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app's settings. Saved on the phone, so they stick after closing the app.
/// Anything that listens to this (like the app's theme) updates automatically
/// when a setting changes.
class AppSettings extends ChangeNotifier {
  bool _dyslexicFont = false;
  double _textScale = 1.0; // 1.0 = normal size
  bool _highContrast = false;
  bool _lightMode = false; // false = dark mode
  bool _readAloud = false; // show speaker buttons
  double _speechRate = 0.5; // 0.3 = very slow, 0.5 = normal, 0.7 = very fast

  bool get dyslexicFont => _dyslexicFont;
  double get textScale => _textScale;
  bool get highContrast => _highContrast;
  bool get lightMode => _lightMode;
  bool get readAloud => _readAloud;
  double get speechRate => _speechRate;

  /// The font used across the whole app. These names must match the
  /// "family:" names in pubspec.yaml.
  String get fontName => _dyslexicFont ? 'OpenDyslexic' : 'Lexend';

  /// Call once when the app starts to load the saved settings.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _dyslexicFont = prefs.getBool('dyslexicFont') ?? false;
      _textScale = prefs.getDouble('textScale') ?? 1.0;
      _highContrast = prefs.getBool('highContrast') ?? false;
      _lightMode = prefs.getBool('lightMode') ?? false;
      _readAloud = prefs.getBool('readAloud') ?? false;
      _speechRate = prefs.getDouble('speechRate') ?? 0.5;
    } catch (_) {
      // If loading fails, just use the defaults
    }
  }

  Future<void> setDyslexicFont(bool value) => _update(() => _dyslexicFont = value);
  Future<void> setTextScale(double value) => _update(() => _textScale = value);
  Future<void> setHighContrast(bool value) => _update(() => _highContrast = value);
  Future<void> setLightMode(bool value) => _update(() => _lightMode = value);
  Future<void> setReadAloud(bool value) => _update(() => _readAloud = value);
  Future<void> setSpeechRate(double value) => _update(() => _speechRate = value);

  Future<void> resetAll() => _update(() {
        _dyslexicFont = false;
        _textScale = 1.0;
        _highContrast = false;
        _lightMode = false;
        _readAloud = false;
        _speechRate = 0.5;
      });

  // Change a value, restyle the app right away, then save it
  Future<void> _update(VoidCallback change) async {
    change();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dyslexicFont', _dyslexicFont);
      await prefs.setDouble('textScale', _textScale);
      await prefs.setBool('highContrast', _highContrast);
      await prefs.setBool('lightMode', _lightMode);
      await prefs.setBool('readAloud', _readAloud);
      await prefs.setDouble('speechRate', _speechRate);
    } catch (_) {
      // Not saved, but it still works until the app closes
    }
  }
}

/// One shared copy of the settings, used anywhere in the app.
final AppSettings appSettings = AppSettings();
