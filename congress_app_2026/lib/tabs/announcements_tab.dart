import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/web_view_tab.dart';

/// Shows the school's Remind announcements.
class AnnouncementsTab extends StatelessWidget {
  const AnnouncementsTab({super.key});

  static const url = 'https://www.remind.com/classes/ac2a67a/messages/014442e4-8211-4193-8d19-84e5a49c6436';

  Future<void> _openRemind() async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'News/Announcements',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),

        // One tap to open Remind outside of our app
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: SizedBox(
            width: double.infinity,
            height: 64,
            child: FilledButton.icon(
              onPressed: _openRemind,
              icon: const Icon(Icons.open_in_new, size: 30),
              label: const Text(
                'Open Remind',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ),

        // The Remind page fills the rest of the screen
        const Expanded(child: WebViewTab(url: url)),
      ],
    );
  }
}