import 'package:flutter/material.dart';

import '../services/tts_service.dart';
import '../settings/app_settings.dart';

/// Settings screen, opened from the gear icon in the top bar.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      // ListenableBuilder rebuilds this screen whenever a setting changes
      body: ListenableBuilder(
        listenable: appSettings,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionTitle('Reading'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Dyslexia-friendly font'),
                      subtitle: const Text('Uses the OpenDyslexic font everywhere in the app'),
                      value: appSettings.dyslexicFont,
                      onChanged: appSettings.setDyslexicFont,
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Text size'),
                          Text('${(appSettings.textScale * 100).round()}%'),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        children: [
                          const Text('A', style: TextStyle(fontSize: 12)),
                          Expanded(
                            child: Slider(
                              value: appSettings.textScale,
                              min: 0.9,
                              max: 1.3,
                              divisions: 4,
                              label: '${(appSettings.textScale * 100).round()}%',
                              onChanged: appSettings.setTextScale,
                            ),
                          ),
                          const Text('A', style: TextStyle(fontSize: 22)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionTitle('Display'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Light mode'),
                      subtitle: const Text('Light background instead of dark'),
                      value: appSettings.lightMode,
                      onChanged: appSettings.setLightMode,
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('High contrast'),
                      subtitle: const Text('Stronger colors and thicker outlines, easier to see'),
                      value: appSettings.highContrast,
                      onChanged: appSettings.setHighContrast,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionTitle('Read aloud'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Read-aloud buttons'),
                      subtitle: const Text(
                        'Adds speaker buttons. Tap one to hear that text. '
                        'The speaker in the top bar reads the whole screen.',
                      ),
                      value: appSettings.readAloud,
                      onChanged: (value) {
                        if (!value) tts.stop();
                        appSettings.setReadAloud(value);
                      },
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Speaking speed'),
                          Text(const {3: 'Very slow', 4: 'Slow', 5: 'Normal', 6: 'Fast', 7: 'Very fast'}[
                                  (appSettings.speechRate * 10).round()] ??
                              'Normal'),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                      child: Slider(
                        value: appSettings.speechRate,
                        min: 0.3,
                        max: 0.7,
                        divisions: 4,
                        onChanged: appSettings.setSpeechRate,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () => tts.speak('This is how I sound at this speed.'),
                          icon: const Icon(Icons.volume_up_outlined),
                          label: const Text('Hear a sample'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Live preview so people can see the changes
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Preview', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        'The quick brown fox jumps over the lazy dog.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: appSettings.resetAll,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reset to defaults'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
