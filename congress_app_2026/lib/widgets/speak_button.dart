import 'package:flutter/material.dart';

import '../services/tts_service.dart';
import '../settings/app_settings.dart';

/// A speaker button that reads [text] out loud. It only appears when
/// "Read aloud buttons" is turned on in Settings. Tap again to stop.
class SpeakButton extends StatelessWidget {
  const SpeakButton(this.text, {super.key, this.filled = false});

  final String text;

  /// A button with a background circle, for use on top of pictures.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([appSettings, tts.current]),
      builder: (context, _) {
        if (!appSettings.readAloud) return const SizedBox.shrink();

        final speaking = tts.current.value == text;
        final icon = Icon(speaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined);
        final tooltip = speaking ? 'Stop reading' : 'Read aloud';
        void onPressed() => tts.toggle(text);

        return filled
            ? IconButton.filledTonal(onPressed: onPressed, icon: icon, tooltip: tooltip)
            : IconButton(onPressed: onPressed, icon: icon, tooltip: tooltip);
      },
    );
  }
}
