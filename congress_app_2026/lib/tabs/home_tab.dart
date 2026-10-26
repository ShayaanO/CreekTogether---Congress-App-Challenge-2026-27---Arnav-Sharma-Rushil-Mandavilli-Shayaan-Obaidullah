import 'package:flutter/material.dart';

import '../pages/tile_pages.dart';
import '../widgets/speak_button.dart';
import '../widgets/web_view_tab.dart';

/// How the grid tiles look.
enum GridListDemoType { imageOnly, header, footer }

class _Photo {
  const _Photo({
    required this.title,
    required this.subtitle,
    this.image,
  });

  final String title;
  final String subtitle;
  final String? image;
}

// The tiles on the home grid.
// If a file is missing, the tile falls back to a colored placeholder.
const List<_Photo> _photos = [
  _Photo(title: 'Creek Schedules', subtitle: ' ', image: 'assets/creek_schedules.png'),
  _Photo(title: 'Grades', subtitle: ' ', image: 'assets/grades.png'),
  _Photo(title: 'Weather', subtitle: ' ', image: 'assets/weather.png'),
  _Photo(title: 'Checklist', subtitle: ' ', image: 'assets/checklist.png'),
  _Photo(title: 'Helpline', subtitle: ' ', image: 'assets/helpline.png'),
  _Photo(title: 'Awareness Month', subtitle: ' ', image: 'assets/awareness_month.png'),
];

// Tiles that open a website inside the app, on their own screen with a back arrow.
const Map<String, String> _linkForTile = {
  'Grades': 'https://ccsdd5.powerschool.com/student/idp',
  
  'Awareness Month': 'https://www.dol.gov/agencies/odep/initiatives/ndeam',
};

// Tiles that jump to a bottom tab instead of opening a new page.
// Format: 'Tile title': tab number
// (0 = Home, 1 = Resources, 2 = Checklist, 3 = Events, 4 = Helpline).
// These numbers match the order in main_shell.dart.
const Map<String, int> _tabForTile = {
  'Checklist': 2,
  'Helpline': 4,
};

void _openInApp(BuildContext context, String title, String url) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: WebViewTab(url: url),
      ),
    ),
  );
}

/// Home tab: banner on top, grid of tiles underneath. The whole tab scrolls.
class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.type, required this.onSelectTab});

  final GridListDemoType type;

  /// Switches the bottom toolbar to another tab. MainShell provides this.
  final void Function(int) onSelectTab;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Banner at the top of the screen
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.campaign, size: 20),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Happy Disability Employment Awareness Month Creek!',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            restorationId: 'grid_view_demo_grid_offset',
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            padding: const EdgeInsets.all(8),
            childAspectRatio: 1,
            children: _photos.map<Widget>((photo) {
              return _GridDemoPhotoItem(
                photo: photo,
                tileStyle: type,
                onSelectTab: onSelectTab,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Allow the text size to shrink to fit in the space.
class _GridTitleText extends StatelessWidget {
  const _GridTitleText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text(text),
    );
  }
}

class _GridDemoPhotoItem extends StatelessWidget {
  const _GridDemoPhotoItem({
    required this.photo,
    required this.tileStyle,
    required this.onSelectTab,
  });

  final _Photo photo;
  final GridListDemoType tileStyle;
  final void Function(int) onSelectTab;

  // Colored square with an icon, used when there is no image (or it's missing)
  Widget _placeholder() {
    return Container(
      color: Colors.primaries[photo.title.hashCode % Colors.primaries.length],
      child: Center(
        child: Icon(
          Icons.image,
          color: Colors.white.withValues(alpha: 0.8),
          size: 48,
        ),
      ),
    );
  }

  // What happens when this tile is tapped
  void _onTap(BuildContext context) {
    // 1. A website inside the app (like Grades -> PowerSchool)
    final link = _linkForTile[photo.title];
    if (link != null) {
      _openInApp(context, photo.title, link);
      return;
    }
    // 2. Jump to a bottom tab (like Checklist)
    final tab = _tabForTile[photo.title];
    if (tab != null) {
      onSelectTab(tab);
      return;
    }
    // 3. Otherwise open the tile's own page (back arrow returns home)
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => pageFor(photo.title)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget image = Semantics(
      label: '${photo.title} ${photo.subtitle}',
      child: Material(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        clipBehavior: Clip.antiAlias,
        child: photo.image != null
            ? Image.asset(
                photo.image!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  // Prints why the image failed (check your terminal)
                  debugPrint('IMAGE ERROR (${photo.image}): $error');
                  return _placeholder();
                },
              )
            : _placeholder(),
      ),
    );

    final Widget tile = switch (tileStyle) {
      GridListDemoType.imageOnly => image,
      GridListDemoType.header => GridTile(
        header: Material(
          color: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
          ),
          clipBehavior: Clip.antiAlias,
          child: GridTileBar(
            title: _GridTitleText(photo.title),
            backgroundColor: Colors.black45,
          ),
        ),
        child: image,
      ),
      GridListDemoType.footer => GridTile(
        footer: Material(
          color: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
          ),
          clipBehavior: Clip.antiAlias,
          child: GridTileBar(
            backgroundColor: Colors.black45,
            title: _GridTitleText(photo.title),
            subtitle: _GridTitleText(photo.subtitle),
          ),
        ),
        child: image,
      ),
    };

    return GestureDetector(
      onTap: () => _onTap(context),
      // A speaker button sits in the corner of each tile when Read aloud is on
      child: Stack(
        children: [
          Positioned.fill(child: tile),
          Positioned(
            top: 2,
            right: 2,
            child: SpeakButton(photo.title, filled: true),
          ),
        ],
      ),
    );
  }
}