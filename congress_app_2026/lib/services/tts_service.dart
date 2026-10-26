import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../settings/app_settings.dart';

/// Reads text out loud. Use the shared copy:  tts.speak('Hello')
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  /// The text being read right now (null when nothing is playing).
  /// Speaker buttons listen to this so they can show a "stop" icon.
  final ValueNotifier<String?> current = ValueNotifier<String?>(null);

  Future<void> _init() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _tts.setCompletionHandler(() => current.value = null);
      _tts.setCancelHandler(() => current.value = null);
      _tts.setErrorHandler((message) {
        debugPrint('TTS ERROR: $message'); // shows the reason in your terminal
        current.value = null;
      });
      _ready = true;
    } catch (e) {
      debugPrint('TTS ERROR: $e');
    }
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    try {
      if (!_ready) await _init();
      if (current.value != null) await _tts.stop();
      await _tts.setSpeechRate(appSettings.speechRate); // speed from Settings
      current.value = text;
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS ERROR: $e');
      current.value = null;
    }
  }

  /// Starts reading, or stops if this same text is already being read.
  Future<void> toggle(String text) async {
    if (current.value == text) {
      await stop();
    } else {
      await speak(text);
    }
  }

  Future<void> stop() async {
    current.value = null;
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

/// One shared copy, used anywhere in the app.
final TtsService tts = TtsService();
