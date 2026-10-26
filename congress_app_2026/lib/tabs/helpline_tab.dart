import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../settings/app_settings.dart';
import '../widgets/speak_button.dart';
import '../widgets/top_banner.dart';

class Helpline {
  const Helpline(this.name, this.number, {this.description});

  final String name;
  final String number; // number that gets dialed
  final String? description; 
}

// phone numbers
const List<Helpline> _helplines = [
  Helpline(
    '988 Suicide & Crisis Lifeline',
    '988',
    description: 'Call or text, free, 24/7 (US)',
  ),
  Helpline(
    '211 Colorado',
    '211',
    description: 'Get Connected. Get Help.',
  ),
  Helpline(
    'Disability Information and Access Line',
    '888-677-1199',
    description: 'Get Help with any Disability Needs.',
  ),
];

/// Helpline tab
class HelplineTab extends StatelessWidget {
  const HelplineTab({super.key});

  Future<void> _call(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number.replaceAll(RegExp(r'[^0-9+]'), ''));
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('CALL ERROR: $e'); // shows the reason in your terminal
      ok = false;
    }
    if (!ok && context.mounted) {
      showTopBanner(context, 'Could not open the phone dialer for $number');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilds when Read aloud is switched on or off in Settings
    return ListenableBuilder(
      listenable: appSettings,
      builder: (context, _) => _buildList(context),
    );
  }

  Widget _buildList(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Helpline', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        const Text('Tap Call to open your phone with the number ready to dial.'),
        const SizedBox(height: 12),
        for (final h in _helplines)
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
              // Reads the name, then the number one digit at a time
              leading: appSettings.readAloud
                  ? SpeakButton(
                      '${h.name}. ${h.description ?? ''} Phone number: '
                      '${h.number.replaceAll(RegExp(r'[^0-9]'), '').split('').join(' ')}',
                    )
                  : null,
              title: Text(h.name),
              subtitle: Text(
                h.description == null ? h.number : '${h.number}\n${h.description}',
              ),
              isThreeLine: h.description != null,
              trailing: FilledButton.icon(
                onPressed: () => _call(context, h.number),
                icon: const Icon(Icons.call),
                label: const Text('Call'),
              ),
            ),
          ),
      ],
    );
  }
}