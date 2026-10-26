import 'package:flutter/material.dart';
import '../widgets/speak_button.dart';
import '../widgets/web_view_tab.dart';

const List<Resource> _resources = [
  Resource(
    label: 'Family',
    icon: Icons.people_outlined,
    page: LinksPage(
      title: 'Family Links',
      links: [
        LinkItem(
          'Smore Family Resource ',
          'https://app.smore.com/n/4wh10',
        ),
        LinkItem(
          'Colorado ABLE',
          'https://www.coloradoable.org/',
        ),
        LinkItem(
          'Developmental Disabilities Resource Center',
          'https://ddrcco.com/',
        ),
        LinkItem(
          'Intellectual and Developmental Disabilities Services & Supports',
          'https://hcpf.colorado.gov/individuals-with-intellectual-developmental-disabilities-services-supports',
        ),
        LinkItem(
          'Developmental Disabilities Waiver',
          'https://hcpf.colorado.gov/developmental-disabilities-waiver-dd',
        ),
      ],
    ),
  ),

  Resource(
    label: 'School',
    icon: Icons.menu_book_outlined,
    page: LinksPage(
      title: 'School Links',
      links: [
        LinkItem(
          'Colorado Developmental Disabilities Council',
          'https://coddc.org/grants/',
        ),
        LinkItem(
          'CCHS Unified',
          'https://sites.google.com/cherrycreekschools.org/cchsunified/unified-sports/unified-spirit?authuser=0',
        ),
        LinkItem(
          'Grade 9-12 Transition Services',
          'https://app.smore.com/n/3451v',
        ),
      ],
    ),
  ),
  Resource(
    label: 'Work',
    icon: Icons.computer_outlined,
    page: LinksPage(
      title: 'Work Links',
      links: [
        LinkItem(
          'Best Buddies Colorado',
          'https://www.bestbuddies.org/colorado/',
        ),
        LinkItem(
          'NDCC Job Boards',
          'https://www.cndcc.org/nd-friendly-businesses---job-boards',
        ),
        LinkItem(
          'Goodwill Colorado',
          'https://goodwillcolorado.org/services/individuals-with-disabilities/',
        ),
        LinkItem(
          'Ability Connection Colorado',
          'https://www.abilityconnectioncolorado.org/programs/employment/',
        ),
        LinkItem(
          'Disability Jobs',
          'https://www.disabilityjobs.org/',
        ),
        LinkItem(
          'Colorado DVR Supported Employment',
          'https://dvr.colorado.gov/dvr-programs-services/supported-employment',
        ),
        LinkItem(
          'City of Denver Employee Resources',
          'https://www.denvergov.org/Government/Agencies-Departments-Offices/Agencies-Departments-Offices-Directory/Human-Rights-Community-Partnerships/Commissions-Advisory-Board/Commission-for-People-with-Disabilities/Employment-In-the-City/Employee-Resources',
        ),
        LinkItem(
          'Colorado Workforce Centers',
          'https://cdle.colorado.gov/jobs-training/workforce-centers',
        ),
      ],
    ),
  ),

  Resource(
    label: 'Sports',
    icon: Icons.sports_soccer_outlined,
    page: LinksPage(
      title: 'Sports Links',
      links: [
        LinkItem(
          'Special Olympics Colorado',
          'https://specialolympicsco.org/',
        ),
        LinkItem(
          'National Sports Center for the Disabled',
          'https://nscd.org/',
        ),
        LinkItem(
          'Creek Unified Sports',
          'https://sites.google.com/cherrycreekschools.org/cchsunified/unified-sports?authuser=0',
        ),
        LinkItem(
          'Paralympic Sport Development',
          'https://www.usopc.org/paralympic-sport-development',
        ),
      ],
    ),
  ),
  Resource(
    label: 'Legal',
    icon: Icons.gavel_outlined,
    page: LinksPage(
      title: 'Legal Links',
      links: [
        LinkItem(
          'Social Security Administration',
          'https://secure.ssa.gov/iApplsRe/start',
        ),
        LinkItem(
          'Social Security Office Locator',
          'https://www.ssa.gov/locator',
        ),
        LinkItem(
          'Appeal a Decision',
          'https://www.ssa.gov/apply/appeal-decision-we-made',
        ),
        LinkItem(
          'Colorado Legal Services',
          'https://www.coloradolegalservices.org/',
        ),
        LinkItem(
          'Law Help Colorado',
          'https://lawhelp.colorado.gov/',
        ),
      ],
    ),
  ),
];

class Resource {
  const Resource({
    required this.label,
    required this.icon,
    this.url,
    this.page,
  }) : assert(url != null || page != null, 'Give a url or a page');

  final String label;
  final IconData icon;
  final String? url; // opens this website inside the app
  final Widget? page; // or shows this screen
}

class InfoPage extends StatelessWidget {
  const InfoPage({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: Theme.of(context).textTheme.headlineSmall)),
            SpeakButton('$title. $body'),
          ],
        ),
        const SizedBox(height: 12),
        Text(body, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

class LinkItem {
  const LinkItem(this.title, this.url, {this.subtitle});

  final String title;
  final String url;
  final String? subtitle;
}

class LinksPage extends StatelessWidget {
  const LinksPage({super.key, required this.title, required this.links});

  final String title;
  final List<LinkItem> links;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              Expanded(child: Text(title, style: Theme.of(context).textTheme.headlineSmall)),
              // Reads the title and the name of every link
              SpeakButton('$title. ${links.map((l) => l.title).join('. ')}'),
            ],
          ),
        ),
        for (final link in links)
          ListTile(
            leading: const Icon(Icons.link),
            title: Text(link.title),
            subtitle: link.subtitle == null ? null : Text(link.subtitle!),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SpeakButton(link.title),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: Text(link.title)),
                  body: WebViewTab(url: link.url),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ResourcesTab extends StatefulWidget {
  const ResourcesTab({super.key});

  @override
  State<ResourcesTab> createState() => _ResourcesTabState();
}

class _ResourcesTabState extends State<ResourcesTab> {
  int _selected = 0;
  // Websites only load the first time you pick them
  final Set<int> _opened = {0};

  Widget _content(Resource r) {
    if (r.url != null) return WebViewTab(url: r.url!);
    return r.page!;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Side bar
        SizedBox(
          width: 84,
          child: ListView(
            children: [
              for (var i = 0; i < _resources.length; i++)
                _SideItem(
                  resource: _resources[i],
                  selected: i == _selected,
                  onTap: () => setState(() {
                    _selected = i;
                    _opened.add(i);
                  }),
                ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: IndexedStack(
            index: _selected,
            children: [
              for (var i = 0; i < _resources.length; i++)
                _opened.contains(i) ? _content(_resources[i]) : const SizedBox.shrink(),
            ],
          ),
        ),
      ],
    );
  }
}

class _SideItem extends StatelessWidget {
  const _SideItem({
    required this.resource,
    required this.selected,
    required this.onTap,
  });

  final Resource resource;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        color: selected ? colors.secondaryContainer : null,
        child: Column(
          children: [
            Icon(resource.icon, color: selected ? colors.primary : null),
            const SizedBox(height: 4),
            Text(
              resource.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}