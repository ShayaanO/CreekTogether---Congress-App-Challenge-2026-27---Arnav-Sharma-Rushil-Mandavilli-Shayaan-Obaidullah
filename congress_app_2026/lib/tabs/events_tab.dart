import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/web_view_tab.dart';

/// Events tab: switch between the school calendar and the Remind announcements.
class EventsTab extends StatefulWidget {
  const EventsTab({super.key});

  static const url = 'https://calendar.google.com/calendar/u/0/embed?ctz=America/Denver&src=c_2255cc795fbd2afb797ab6faaedc509f21396e899ec9c16bf825a72ad48dc4ab@group.calendar.google.com';

  static const announcementsUrl = 'https://www.remind.com/classes/ac2a67a/messages/014442e4-8211-4193-8d19-84e5a49c6436';

  @override
  State<EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<EventsTab> {
  int _section = 0; // 0 = Calendar, 1 = Announcements
  bool _announcementsOpened = false; // the Remind page only loads once it's first opened

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Big switch between the two sections
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                minimumSize: const Size(0, 56),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              segments: const [
                ButtonSegment(
                  value: 0,
                  icon: Icon(Icons.calendar_month),
                  label: Text('Calendar'),
                ),
                ButtonSegment(
                  value: 1,
                  icon: Icon(Icons.campaign),
                  label: Text('Announcements'),
                ),
              ],
              selected: {_section},
              onSelectionChanged: (selection) {
                setState(() {
                  _section = selection.first;
                  if (_section == 1) _announcementsOpened = true;
                });
              },
            ),
          ),
        ),

        // IndexedStack keeps each section's page when you switch back and forth
        Expanded(
          child: IndexedStack(
            index: _section,
            children: [
              const WebViewTab(url: EventsTab.url),
              _announcementsOpened ? const _AnnouncementsView() : const SizedBox.shrink(),
            ],
          ),
        ),
      ],
    );
  }
}

/// The Remind announcements page, with a button to open Remind itself.
class _AnnouncementsView extends StatelessWidget {
  const _AnnouncementsView();

  Future<void> _openRemind() async {
    await launchUrl(
      Uri.parse(EventsTab.announcementsUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
        const Expanded(child: WebViewTab(url: EventsTab.announcementsUrl)),
      ],
    );
  }
}