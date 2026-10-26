import 'package:flutter/material.dart';

import 'pages/settings_page.dart';
import 'services/screen_text.dart';
import 'services/tts_service.dart';
import 'settings/app_settings.dart';
import 'tabs/checklist_tab.dart';
import 'tabs/events_tab.dart';
import 'tabs/helpline_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/resources_tab.dart';

/// The main screen: top bar, the selected tab, and the bottom toolbar.

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.type});

  final GridListDemoType type;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0; // which bottom tab is selected
  final Set<int> _opened = {}; // website tabs only load after they're first opened
  final GlobalKey _bodyKey = GlobalKey(); 

  // Title shown in the top bar for each tab
  static const _titles = ['Home', 'Resources', 'Checklist', 'Events', 'Helpline'];

  // Switchs to a tab 
  void _selectTab(int i) {
    tts.stop(); // stop reading when you change tabs
    setState(() {
      _index = i;
      _opened.add(i); // marks this tab as opened so its website loads
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      HomeTab(type: widget.type, onSelectTab: _selectTab), // 0
      _opened.contains(1) ? const ResourcesTab() : const SizedBox.shrink(), // 1 
      const ChecklistTab(), // 2
      _opened.contains(3) ? const EventsTab() : const SizedBox.shrink(), // 3 
      const HelplineTab(), // 4
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_titles[_index]),
        actions: [
          //  Reads the whole screen when Read aloud is on in Settings
          ListenableBuilder(
            listenable: appSettings,
            builder: (context, _) {
              if (!appSettings.readAloud) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.volume_up_outlined),
                tooltip: 'Read this screen',
                onPressed: () {
                  final bodyContext = _bodyKey.currentContext;
                  if (bodyContext != null) {
                    tts.toggle(visibleTextIn(bodyContext));
                  }
                },
              );
            },
          ),
          // Opens the Settings screen
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      // IndexedStack keeps each tab's state (like scroll position) when you switch
      body: KeyedSubtree(
        key: _bodyKey,
        child: IndexedStack(index: _index, children: tabs),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: _Emoji('🏠', selected: false),
            selectedIcon: _Emoji('🏠', selected: true),
            label: 'Home',
          ),
          NavigationDestination(
            icon: _Emoji('🗂️', selected: false),
            selectedIcon: _Emoji('🗂️', selected: true),
            label: 'Resources',
          ),
          NavigationDestination(
            icon: _Emoji('✅', selected: false),
            selectedIcon: _Emoji('✅', selected: true),
            label: 'Checklist',
          ),
          NavigationDestination(
            icon: _Emoji('🗓️', selected: false),
            selectedIcon: _Emoji('🗓️', selected: true),
            label: 'Events',
          ),
          NavigationDestination(
            icon: _Emoji('📞', selected: false),
            selectedIcon: _Emoji('📞', selected: true),
            label: 'Helpline',
          ),
        ],
      ),
    );
  }
}

/// Emoji icon for the bottom bar. Dimmer and smaller when not selected.
class _Emoji extends StatelessWidget {
  const _Emoji(this.emoji, {required this.selected});

  final String emoji;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: selected ? 1 : 0.6,
      child: Text(emoji, style: TextStyle(fontSize: selected ? 26 : 24)),
    );
  }
}