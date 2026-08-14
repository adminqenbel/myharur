import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() => runApp(const MyHarurApp());

class MyHarurApp extends StatelessWidget {
  const MyHarurApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyHarur',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const TownShell(),
    );
  }
}

class AppTheme {
  static const ink = Color(0xFF15211F);
  static const muted = Color(0xFF697570);
  static const mist = Color(0xFFF2F6F5);
  static const line = Color(0xFFDCE5E1);
  static const green = Color(0xFF007F63);
  static const red = Color(0xFFE44545);
  static const blue = Color(0xFF267AF4);

  static final light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: green,
      brightness: Brightness.light,
      surface: Colors.white,
    ),
    textTheme: const TextTheme(
      displaySmall: TextStyle(
          fontSize: 33, height: 1.04, fontWeight: FontWeight.w800, color: ink),
      headlineSmall: TextStyle(
          fontSize: 24, height: 1.15, fontWeight: FontWeight.w800, color: ink),
      titleLarge: TextStyle(
          fontSize: 20, height: 1.2, fontWeight: FontWeight.w800, color: ink),
      titleMedium: TextStyle(
          fontSize: 16, height: 1.2, fontWeight: FontWeight.w700, color: ink),
      bodyLarge: TextStyle(fontSize: 16, height: 1.35, color: ink),
      bodyMedium: TextStyle(fontSize: 14, height: 1.35, color: muted),
      labelLarge: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: .4),
    ),
  );
}

class TownShell extends StatefulWidget {
  const TownShell({super.key});

  @override
  State<TownShell> createState() => _TownShellState();
}

class _TownShellState extends State<TownShell> {
  int selected = 0;

  static const pages = [HomePage(), ExplorePage(), AlertsPage(), AccountPage()];
  static const labels = ['Home', 'Explore', 'Alerts', 'Account'];
  static const icons = ['home', 'compass', 'bell', 'user'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const TownDrawer(),
      body: SafeArea(child: pages[selected]),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
          child: Container(
            height: 76,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .94),
              border: Border.all(color: const Color(0xFFE2EBE8)),
              borderRadius: BorderRadius.circular(38),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x140F2922),
                    blurRadius: 26,
                    offset: Offset(0, 8))
              ],
            ),
            child: Row(
              children: List.generate(labels.length, (index) {
                final active = selected == index;
                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () => setState(() => selected = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFFE9F6F1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppIcon(icons[index],
                              color: active ? AppTheme.green : AppTheme.ink,
                              size: 22),
                          const SizedBox(height: 3),
                          Text(labels[index],
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: active
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color:
                                      active ? AppTheme.green : AppTheme.ink)),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TownHeader(showSearch: true),
                const SizedBox(height: 24),
                Text('Good evening,',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: AppTheme.muted)),
                Text('Harur is happening.',
                    style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 18),
                const LocationPill(),
                const SizedBox(height: 24),
                const CategoryRail(),
                const SizedBox(height: 28),
                const MiniMapCard(),
                const SizedBox(height: 26),
                const SectionHeader(label: 'LOCAL UPDATE', action: 'View all'),
                const SizedBox(height: 12),
                const FeaturedNewsCard(),
                const SizedBox(height: 26),
                const SectionHeader(label: 'QUICK ACTIONS'),
                const SizedBox(height: 12),
                const QuickActions(),
                const SizedBox(height: 26),
                const SectionHeader(label: 'HARUR & DHARMAPURI WEATHER'),
                const SizedBox(height: 12),
                const WeatherCards(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class TownHeader extends StatelessWidget {
  const TownHeader({super.key, required this.showSearch});
  final bool showSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Builder(
            builder: (context) => RoundIconButton(
                icon: 'menu', onTap: () => Scaffold.of(context).openDrawer())),
        const Spacer(),
        const Column(
          children: [
            Text('myharur',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.7)),
            Text('digital town',
                style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.muted,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w800)),
          ],
        ),
        const Spacer(),
        if (showSearch)
          RoundIconButton(icon: 'search', onTap: () {})
        else
          const SizedBox(width: 48),
      ],
    );
  }
}

class LocationPill extends StatelessWidget {
  const LocationPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
          color: AppTheme.mist,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.line)),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        AppIcon('pin', color: AppTheme.green, size: 18),
        SizedBox(width: 7),
        Text('Harur, Dharmapuri',
            style: TextStyle(fontWeight: FontWeight.w800)),
        SizedBox(width: 5),
        Icon(Icons.keyboard_arrow_down_rounded, size: 20),
      ]),
    );
  }
}

class CategoryRail extends StatelessWidget {
  const CategoryRail({super.key});
  static const items = [
    ('news', 'News'),
    ('cloud', 'Weather'),
    ('heart', 'Help'),
    ('bag', 'Market'),
    ('briefcase', 'Jobs'),
    ('calendar', 'Events'),
    ('chat', 'Chat'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 98,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return SizedBox(
            width: 74,
            child: Column(children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                    color: index == 0 ? const Color(0xFFE9F6F1) : AppTheme.mist,
                    border: Border.all(
                        color: index == 0
                            ? const Color(0xFF9DD8C5)
                            : AppTheme.mist),
                    borderRadius: BorderRadius.circular(21)),
                child: Center(
                    child: AppIcon(item.$1,
                        color: index == 0 ? AppTheme.green : AppTheme.ink,
                        size: 27)),
              ),
              const SizedBox(height: 8),
              Text(item.$2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          index == 0 ? FontWeight.w800 : FontWeight.w600)),
            ]),
          );
        },
      ),
    );
  }
}

class MiniMapCard extends StatelessWidget {
  const MiniMapCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 192,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
          color: const Color(0xFFE8F2E9),
          borderRadius: BorderRadius.circular(28)),
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: MapLinesPainter())),
        Positioned(
            left: 22,
            top: 20,
            child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .9),
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('Your local view',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w800)))),
        const Positioned(right: 36, bottom: 40, child: _MapMarker()),
        Positioned(
            left: 20,
            right: 20,
            bottom: 16,
            child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                    color: const Color(0xFF15211F),
                    borderRadius: BorderRadius.circular(18)),
                child: const Row(children: [
                  AppIcon('pin', color: Colors.white, size: 18),
                  SizedBox(width: 9),
                  Expanded(
                      child: Text(
                          'Location is used only when you choose to share it.',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600))),
                  Icon(Icons.chevron_right_rounded, color: Colors.white)
                ]))),
      ]),
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker();
  @override
  Widget build(BuildContext context) => Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
          color: AppTheme.green,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x44007F63), blurRadius: 16)]),
      child:
          const Center(child: AppIcon('pin', color: Colors.white, size: 24)));
}

class MapLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = Colors.white.withValues(alpha: .78)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final minor = Paint()
      ..color = const Color(0xFFC7DFC9)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final a = Path()
      ..moveTo(-30, size.height * .28)
      ..cubicTo(size.width * .2, 0, size.width * .48, size.height * .75,
          size.width + 25, size.height * .28);
    final b = Path()
      ..moveTo(size.width * .08, size.height + 20)
      ..cubicTo(size.width * .16, size.height * .65, size.width * .66,
          size.height * .65, size.width * .82, -20);
    canvas.drawPath(a, road);
    canvas.drawPath(b, road);
    canvas.drawLine(Offset(0, size.height * .62),
        Offset(size.width, size.height * .46), minor);
    canvas.drawLine(Offset(size.width * .35, 0),
        Offset(size.width * .18, size.height), minor);
    canvas.drawCircle(Offset(size.width * .2, size.height * .32), 12,
        Paint()..color = const Color(0xFFB9DDBB));
    canvas.drawCircle(Offset(size.width * .75, size.height * .2), 20,
        Paint()..color = const Color(0xFFB9DDBB));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FeaturedNewsCard extends StatelessWidget {
  const FeaturedNewsCard({super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(
            color: const Color(0xFFFFF7E8),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: const Color(0xFFF1E0BE))),
        child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                AppIcon('news', color: Color(0xFFC17600), size: 21),
                SizedBox(width: 8),
                Text('LOCAL NEWS · DEMO',
                    style: TextStyle(
                        color: Color(0xFFC17600),
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w900)),
                Spacer(),
                Icon(Icons.arrow_forward_rounded, color: AppTheme.ink)
              ]),
              SizedBox(height: 17),
              Text('A calmer, connected town starts here.',
                  style: TextStyle(
                      fontSize: 23, height: 1.1, fontWeight: FontWeight.w900)),
              SizedBox(height: 9),
              Text(
                  'Verified local news, weather, help and community updates — all in one place.',
                  style: TextStyle(color: AppTheme.muted, height: 1.35)),
              SizedBox(height: 17),
              Text('Today · Harur',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.muted,
                      fontWeight: FontWeight.w700)),
            ]),
      );
}

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});
  static const items = [
    ('alert', 'Ask nearby', AppTheme.red),
    ('news', 'Submit news', AppTheme.blue),
    ('calendar', 'View events', AppTheme.green),
    ('chat', 'Town chat', AppTheme.ink)
  ];
  @override
  Widget build(BuildContext context) => GridView.builder(
        itemCount: items.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.25,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return SoftCard(
              child: Row(children: [
            Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: item.$3.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(13)),
                child:
                    Center(child: AppIcon(item.$1, color: item.$3, size: 21))),
            const SizedBox(width: 10),
            Expanded(
                child: Text(item.$2,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800)))
          ]));
        },
      );
}

class WeatherCards extends StatelessWidget {
  const WeatherCards({super.key});
  @override
  Widget build(BuildContext context) => const Row(children: [
        Expanded(
            child: WeatherCard(
                place: 'Harur', temperature: '28°', caption: 'Partly cloudy')),
        SizedBox(width: 12),
        Expanded(
            child: WeatherCard(
                place: 'Dharmapuri',
                temperature: '30°',
                caption: 'Clear skies'))
      ]);
}

class WeatherCard extends StatelessWidget {
  const WeatherCard(
      {super.key,
      required this.place,
      required this.temperature,
      required this.caption});
  final String place, temperature, caption;
  @override
  Widget build(BuildContext context) => SoftCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const AppIcon('cloud', color: AppTheme.blue, size: 26),
        const SizedBox(height: 16),
        Text(temperature,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
        Text(place, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(caption,
            style: const TextStyle(fontSize: 12, color: AppTheme.muted))
      ]));
}

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  static const cards = [
    ('bag', 'Marketplace', 'Buy, sell, reuse'),
    ('briefcase', 'Jobs', 'Find local work'),
    ('calendar', 'Events', 'What is on nearby'),
    ('store', 'Shops', 'Offers around town'),
    ('award', 'Rankings', 'Celebrate local heroes'),
    ('heart', 'Support', 'We are here to help'),
  ];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TownHeader(showSearch: true),
                const SizedBox(height: 32),
                Text('Explore',
                    style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 7),
                Text('Everyday things, from your town.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: AppTheme.muted)),
                const SizedBox(height: 26),
                GridView.builder(
                  itemCount: cards.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: .98,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14),
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    return SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                  color: AppTheme.mist,
                                  borderRadius: BorderRadius.circular(16)),
                              child: Center(
                                  child: AppIcon(card.$1,
                                      color: AppTheme.green, size: 25))),
                          const Spacer(),
                          Text(card.$2,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text(card.$3,
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.muted)),
                          const SizedBox(height: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 19),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TownHeader(showSearch: false),
          const SizedBox(height: 32),
          Text('Safety & updates',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text('Fast help when it matters.',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppTheme.muted)),
          const SizedBox(height: 25),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
                color: const Color(0xFFFFECEB),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFF8C9C5))),
            child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    AppIcon('alert', color: AppTheme.red, size: 27),
                    Spacer(),
                    Icon(Icons.arrow_forward_rounded, color: AppTheme.red)
                  ]),
                  SizedBox(height: 23),
                  Text('Need immediate help?',
                      style:
                          TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
                  SizedBox(height: 6),
                  Text('Raise a nearby-help request or report an emergency.',
                      style: TextStyle(color: AppTheme.muted)),
                  SizedBox(height: 18),
                  _AlertAction()
                ]),
          ),
          const SizedBox(height: 28),
          const SectionHeader(label: 'TRACK REQUEST'),
          const SizedBox(height: 12),
          const SoftCard(
              child: Row(children: [
            AppIcon('clock', color: AppTheme.green, size: 22),
            SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('No active requests',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  SizedBox(height: 3),
                  Text('Your reports and help requests appear here.',
                      style: TextStyle(fontSize: 12, color: AppTheme.muted))
                ])),
            Icon(Icons.chevron_right_rounded)
          ])),
          const SizedBox(height: 28),
          const SectionHeader(label: 'GOVERNMENT UPDATES'),
          const SizedBox(height: 12),
          const SoftCard(
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AppIcon('news', color: AppTheme.blue, size: 22),
            SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Official updates will appear here',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text(
                      'Only verified government officials can publish to this channel.',
                      style: TextStyle(fontSize: 12, color: AppTheme.muted))
                ]))
          ])),
        ],
      ),
    );
  }
}

class _AlertAction extends StatelessWidget {
  const _AlertAction();
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: AppTheme.red, borderRadius: BorderRadius.circular(16)),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        AppIcon('heart', color: Colors.white, size: 20),
        SizedBox(width: 8),
        Text('Ask nearby for help',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900))
      ]));
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});
  @override
  Widget build(BuildContext context) => const SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TownHeader(showSearch: false),
        SizedBox(height: 30),
        Row(children: [
          CircleAvatar(
              radius: 31,
              backgroundColor: Color(0xFFE9F6F1),
              child: AppIcon('user', color: AppTheme.green, size: 30)),
          SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Welcome to MyHarur',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            SizedBox(height: 3),
            Text('Sign in to personalise your town',
                style: TextStyle(color: AppTheme.muted))
          ])
        ]),
        SizedBox(height: 25),
        SoftCard(
            child: Row(children: [
          AppIcon('shield', color: AppTheme.green, size: 22),
          SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Account security',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                SizedBox(height: 3),
                Text('Google sign-in and optional MFA',
                    style: TextStyle(fontSize: 12, color: AppTheme.muted))
              ])),
          Icon(Icons.chevron_right_rounded)
        ])),
        SizedBox(height: 28),
        SectionHeader(label: 'YOUR MYHARUR'),
        SizedBox(height: 12),
        AccountRows(),
        SizedBox(height: 28),
        SectionHeader(label: 'SUPPORT'),
        SizedBox(height: 12),
        SoftCard(
            child: Row(children: [
          AppIcon('chat', color: AppTheme.blue, size: 22),
          SizedBox(width: 12),
          Expanded(
              child: Text('Chat with support',
                  style: TextStyle(fontWeight: FontWeight.w800))),
          Icon(Icons.chevron_right_rounded)
        ]))
      ]));
}

class AccountRows extends StatelessWidget {
  const AccountRows({super.key});
  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
          border: Border.all(color: AppTheme.line),
          borderRadius: BorderRadius.circular(24)),
      child: const Column(children: [
        AccountRow(
            icon: 'pin', label: 'My location', detail: 'Harur, Dharmapuri'),
        Divider(height: 1),
        AccountRow(
            icon: 'bell',
            label: 'Notifications',
            detail: 'Local updates and alerts'),
        Divider(height: 1),
        AccountRow(
            icon: 'shield',
            label: 'Privacy & permissions',
            detail: 'Manage your data')
      ]));
}

class AccountRow extends StatelessWidget {
  const AccountRow(
      {super.key,
      required this.icon,
      required this.label,
      required this.detail});
  final String icon, label, detail;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        AppIcon(icon, color: AppTheme.ink, size: 22),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(detail,
              style: const TextStyle(fontSize: 12, color: AppTheme.muted))
        ])),
        const Icon(Icons.chevron_right_rounded)
      ]));
}

class TownDrawer extends StatelessWidget {
  const TownDrawer({super.key});
  @override
  Widget build(BuildContext context) => Drawer(
          child: SafeArea(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            const Padding(
                padding: EdgeInsets.fromLTRB(24, 26, 24, 22),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('myharur',
                          style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.w900)),
                      SizedBox(height: 4),
                      Text('Your digital town',
                          style: TextStyle(color: AppTheme.muted))
                    ])),
            const Divider(height: 1),
            const DrawerItem(icon: 'chat', label: 'Town chat'),
            const DrawerItem(icon: 'news', label: 'Government updates'),
            const DrawerItem(icon: 'news', label: 'Submit news'),
            const DrawerItem(icon: 'calendar', label: 'My events'),
            const DrawerItem(icon: 'heart', label: 'Help & support'),
            const Spacer(),
            Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: AppTheme.mist,
                    borderRadius: BorderRadius.circular(18)),
                child: const Text(
                    'Admin tools automatically appear here when your role grants access.',
                    style: TextStyle(fontSize: 12, color: AppTheme.muted)))
          ])));
}

class DrawerItem extends StatelessWidget {
  const DrawerItem({super.key, required this.icon, required this.label});
  final String icon, label;
  @override
  Widget build(BuildContext context) => ListTile(
      leading: AppIcon(icon, color: AppTheme.ink, size: 22),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => Navigator.pop(context));
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.label, this.action});
  final String label;
  final String? action;
  @override
  Widget build(BuildContext context) => Row(children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.muted,
                fontSize: 12,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w900)),
        const Spacer(),
        if (action != null)
          Text(action!,
              style: const TextStyle(
                  color: AppTheme.blue, fontWeight: FontWeight.w800))
      ]);
}

class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.line),
          boxShadow: const [
            BoxShadow(
                color: Color(0x080F2922), blurRadius: 14, offset: Offset(0, 5))
          ]),
      child: child);
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.onTap});
  final String icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTheme.line),
              shape: BoxShape.circle),
          child: Center(child: AppIcon(icon, color: AppTheme.ink, size: 23))));
}

class AppIcon extends StatelessWidget {
  const AppIcon(this.name,
      {super.key, this.color = AppTheme.ink, this.size = 24});
  final String name;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset('assets/icons/$name.svg',
          width: size,
          height: size,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          semanticsLabel: name);
}
