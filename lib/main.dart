import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import 'services/supabase_service.dart';
import 'features/onboarding_page.dart';
import 'features/phase_two_pages.dart';
import 'features/marketplace_page.dart';
import 'features/jobs_page.dart';
import 'features/events_page.dart';
import 'features/chat_page.dart';
import 'features/shops_page.dart';
import 'features/rankings_page.dart';
import 'features/auth_page.dart';
import 'features/admin_dashboard_page.dart';

void main() => runApp(const MyHarurApp());

class MyHarurApp extends StatelessWidget {
  const MyHarurApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyHarur',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: kIsWeb
          ? const TownShell()
          : (AuthService.isAuthenticated ? const TownShell() : const TownOnboardingFlowPage()),
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
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeInOutCubic,
          switchOutCurve: Curves.easeInOutCubic,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey<int>(selected),
            child: pages[selected],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(38),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 76,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.82),
                  border: Border.all(color: const Color(0xFF00D09C).withValues(alpha: 0.35)),
                  borderRadius: BorderRadius.circular(38),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF007F63).withValues(alpha: 0.16),
                      blurRadius: 28,
                      offset: const Offset(0, 8),
                    ),
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
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFF007F63)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF007F63).withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppIcon(
                                icons[index],
                                color: active ? Colors.white : AppTheme.ink,
                                size: 22,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                labels[index],
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                                  color: active ? Colors.white : AppTheme.ink,
                                ),
                              ),
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
        ),
      ),
    );
  }
}

Future<void> launchAppUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

void showDownloadApkSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0C1311),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D09C).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF00D09C).withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.android_rounded, color: Color(0xFF00D09C), size: 28),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Download MyHarur for Android',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'v0.1.0 (Stable) • 24.2 MB • Official Build',
                    style: TextStyle(color: Color(0xFF8E9F98), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: const Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF00D09C), size: 16),
                    SizedBox(width: 8),
                    Text('Direct high-speed APK download', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF00D09C), size: 16),
                    SizedBox(width: 8),
                    Text('Instant emergency SOS & town alerts', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF00D09C), size: 16),
                    SizedBox(width: 8),
                    Text('Zero trackers, verified local build', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D09C),
                foregroundColor: const Color(0xFF070B0A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.download_for_offline_rounded, size: 22),
              label: const Text('Download APK File (Direct)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              onPressed: () {
                Navigator.pop(ctx);
                launchAppUrl('https://github.com/adminqenbel/myharur/releases/latest/download/myharur.apk');
              },
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00E5FF),
                side: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.open_in_browser_rounded, size: 20),
              label: const Text('Open Interactive Download Portal', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              onPressed: () {
                Navigator.pop(ctx);
                launchAppUrl('./download.html');
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class DownloadApkBanner extends StatelessWidget {
  const DownloadApkBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => showDownloadApkSheet(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F2620), Color(0xFF16362E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF00D09C).withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF007F63).withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF00D09C).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF00D09C).withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.android_rounded, color: Color(0xFF00D09C), size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'MyHarur Android App',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D09C),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('APK', style: TextStyle(color: Color(0xFF070B0A), fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Tap to download official APK with instant alerts.',
                    style: TextStyle(color: Color(0xFF9EAEA8), fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF00D09C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Download', style: TextStyle(color: Color(0xFF070B0A), fontWeight: FontWeight.w900, fontSize: 12)),
            ),
          ],
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
                const SizedBox(height: 14),
                const DownloadApkBanner(),
                const SizedBox(height: 20),
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/brand/myharur_icon.svg',
              width: 28,
              height: 28,
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('myharur',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.7)),
                Text('digital town',
                    style: TextStyle(
                        fontSize: 9,
                        color: AppTheme.muted,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ],
        ),
        const Spacer(),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => showDownloadApkSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF007F63).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF007F63).withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.android_rounded, size: 15, color: Color(0xFF007F63)),
                SizedBox(width: 4),
                Text('APK', style: TextStyle(color: Color(0xFF007F63), fontWeight: FontWeight.w900, fontSize: 11)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (showSearch)
          RoundIconButton(icon: 'search', onTap: () {})
        else
          const SizedBox(width: 40),
      ],
    );
  }
}class LocationPill extends StatelessWidget {
  const LocationPill({super.key});

  @override
  Widget build(BuildContext context) {
    final locationName = AuthService.currentProfile.wardLocality;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LocationSelectionPage())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
            color: AppTheme.mist,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.line)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const AppIcon('pin', color: AppTheme.green, size: 18),
          const SizedBox(width: 7),
          Text(locationName,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(width: 5),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
        ]),
      ),
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
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return SizedBox(
            width: 74,
            child: InkWell(
              borderRadius: BorderRadius.circular(21),
              onTap: () => _openCategory(context, item.$1),
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
                      size: 26),
                ),
              ),
              const SizedBox(height: 8),
              Text(item.$2,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          index == 0 ? FontWeight.w800 : FontWeight.w600,
                      color: index == 0 ? AppTheme.green : AppTheme.ink))
              ]),
            ),
          );
        },
      ),
    );
  }
}

void _openCategory(BuildContext context, String category) {
  Widget page;
  switch (category) {
    case 'news':
      page = const NewsHubPage();
      break;
    case 'cloud':
      page = const WeatherHubPage();
      break;
    case 'heart':
      page = const EmergencyReportPage();
      break;
    case 'bag':
      page = const MarketplacePage();
      break;
    case 'briefcase':
      page = const JobsPage();
      break;
    case 'calendar':
      page = const EventsPage();
      break;
    case 'chat':
      page = const TownChatPage();
      break;
    default:
      page = const NewsHubPage();
  }
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}

class MiniMapCard extends StatelessWidget {
  const MiniMapCard({super.key});

  @override
  Widget build(BuildContext context) {
    final locationName = AuthService.currentProfile.wardLocality;

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LocationSelectionPage()),
      ),
      child: Container(
        height: 192,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
            color: const Color(0xFFE8F2E9),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF9DD8C5))),
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(color: Color(0xFF007F63), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text('Pinned: $locationName',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                    ],
                  ))),
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
                    AppIcon('pin', color: Color(0xFF00D09C), size: 18),
                    SizedBox(width: 9),
                    Expanded(
                        child: Text(
                            'GPS 12.0624° N, 78.4983° E · Tap to re-pin location',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600))),
                    Icon(Icons.chevron_right_rounded, color: Colors.white)
                  ]))),
        ]),
      ),
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
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const NewsHubPage())),
        child: Container(
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
        ),
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
          return InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              if (item.$1 == 'alert') {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const EmergencyReportPage()));
              } else if (item.$1 == 'news') {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NewsHubPage()));
              } else if (item.$1 == 'calendar') {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EventsPage()));
              } else if (item.$1 == 'chat') {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TownChatPage()));
              }
            },
            child: SoftCard(
                child: Row(children: [
              Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                      color: item.$3.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(13)),
                  child: Center(
                      child: AppIcon(item.$1, color: item.$3, size: 21))),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(item.$2,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800)))
            ])),
          );
        },
      );
}

class WeatherCards extends StatelessWidget {
  const WeatherCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: WeatherService.getLatestSnapshot('Harur'),
            builder: (context, snapshot) {
              final temp = snapshot.hasData
                  ? "${(snapshot.data!['temperature_c'] as num).round()}°"
                  : "32°";
              final condition = snapshot.hasData
                  ? (snapshot.data!['condition'] as String)
                  : "Partly Cloudy";
              return WeatherCard(
                place: 'Harur',
                temperature: temp,
                caption: condition,
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: WeatherService.getLatestSnapshot('Dharmapuri'),
            builder: (context, snapshot) {
              final temp = snapshot.hasData
                  ? "${(snapshot.data!['temperature_c'] as num).round()}°"
                  : "33°";
              final condition = snapshot.hasData
                  ? (snapshot.data!['condition'] as String)
                  : "Sunny & Breeze";
              return WeatherCard(
                place: 'Dharmapuri',
                temperature: temp,
                caption: condition,
              );
            },
          ),
        ),
      ],
    );
  }
}

class WeatherCard extends StatelessWidget {
  const WeatherCard(
      {super.key,
      required this.place,
      required this.temperature,
      required this.caption});
  final String place, temperature, caption;
  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const WeatherHubPage())),
        child: SoftCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppIcon('cloud', color: AppTheme.blue, size: 26),
          const SizedBox(height: 16),
          Text(temperature,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
          Text(place, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppTheme.muted))
        ])),
      );
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
                    return InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        final Widget page = switch (card.$1) {
                          'bag' => const MarketplacePage(),
                          'briefcase' => const JobsPage(),
                          'calendar' => const EventsPage(),
                          'store' => const ShopsPage(),
                          'award' => const RankingsPage(),
                          'heart' => const EmergencyReportPage(),
                          _ => const HomePage(),
                        };
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
                      },
                      child: SoftCard(
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
          InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EmergencyReportPage())),
            child: Container(
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
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NewsHubPage())),
            child: const SoftCard(
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
          ),
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
  Widget build(BuildContext context) {
    final profile = AuthService.currentProfile;
    final isLoggedIn = AuthService.isAuthenticated;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TownHeader(showSearch: false),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F6F1),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF9DD8C5), width: 2),
                ),
                child: Center(
                  child: Text(
                    profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : 'H',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF007F63)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF15211F)),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF007F63),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            profile.role.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'MMID: ${profile.mmid}',
                          style: const TextStyle(color: Color(0xFF697570), fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AuthPage()),
            ),
            child: SoftCard(
              child: Row(
                children: [
                  const AppIcon('shield', color: AppTheme.green, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLoggedIn ? 'Edit Personal Details & Security' : 'Sign In / Register MMID',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isLoggedIn ? '${profile.wardLocality} • ${profile.bloodGroup}' : 'Google OAuth, Password & MMID generation',
                          style: const TextStyle(fontSize: 12, color: AppTheme.muted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          const SectionHeader(label: 'TOWN SERVICES & RECOVERY'),
          const SizedBox(height: 12),
          const AccountRows(),
          const SizedBox(height: 28),
          const SectionHeader(label: 'ADMINISTRATION & SUPPORT'),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
            ),
            child: const SoftCard(
              child: Row(
                children: [
                  AppIcon('shield', color: AppTheme.red, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SuperAdmin Governance Console', style: TextStyle(fontWeight: FontWeight.w800)),
                        SizedBox(height: 2),
                        Text('Passkey protected moderation & consensus', style: TextStyle(fontSize: 12, color: AppTheme.muted)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EmergencyReportPage()),
            ),
            child: const SoftCard(
              child: Row(
                children: [
                  AppIcon('heart', color: AppTheme.green, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Emergency SOS & Hotlines', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          const QenbelBrandBadge(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class AccountRows extends StatelessWidget {
  const AccountRows({super.key});
  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
          border: Border.all(color: AppTheme.line),
          borderRadius: BorderRadius.circular(24)),
      child: Column(children: [
        AccountRow(
            icon: 'pin',
            label: 'My location',
            detail: 'Harur, Dharmapuri',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const LocationSelectionPage()))),
        const Divider(height: 1),
        AccountRow(
            icon: 'bell',
            label: 'Notifications & Alerts',
            detail: 'Local updates and nearby SOS alerts',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const EmergencyReportPage()))),
        const Divider(height: 1),
        AccountRow(
            icon: 'shield',
            label: 'Privacy & Credentials',
            detail: 'Argon2id KDF & Google Account Link',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const AuthPage()))),
      ]));
}

class AccountRow extends StatelessWidget {
  const AccountRow(
      {super.key,
      required this.icon,
      required this.label,
      required this.detail,
      this.onTap});
  final String icon, label, detail;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      child: Padding(
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
          ])));
}

class TownDrawer extends StatelessWidget {
  const TownDrawer({super.key});
  @override
  Widget build(BuildContext context) => Drawer(
          child: SafeArea(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/brand/myharur_icon.svg',
                      width: 44,
                      height: 44,
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('myharur',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        SizedBox(height: 2),
                        Text('Your digital town',
                            style: TextStyle(color: AppTheme.muted, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                )),
            const Divider(height: 1),
            DrawerItem(
                icon: 'chat',
                label: 'Town chat',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TownChatPage()));
                }),
            DrawerItem(
                icon: 'news',
                label: 'Government updates',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NewsHubPage()));
                }),
            DrawerItem(
                icon: 'news',
                label: 'Submit news',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NewsHubPage()));
                }),
            DrawerItem(
                icon: 'calendar',
                label: 'Events & Tournaments',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EventsPage()));
                }),
            DrawerItem(
                icon: 'phone',
                label: '📱 Download Android APK',
                onTap: () {
                  Navigator.pop(context);
                  showDownloadApkSheet(context);
                }),
            DrawerItem(
                icon: 'heart',
                label: 'Help & support',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const EmergencyReportPage()));
                }),
            const Spacer(),
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const AdminDashboardPage()));
              },
              child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: const Color(0xFFE9F6F1),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF9DD8C5))),
                  child: const Row(
                    children: [
                      AppIcon('shield', color: AppTheme.green, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Admin & Super Admin Tools',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.green)),
                            Text('Moderation, 3-Vote termination & AIDs',
                                style: TextStyle(
                                    fontSize: 11, color: AppTheme.muted)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: AppTheme.green, size: 18),
                    ],
                  )),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: QenbelBrandBadge(),
            ),
          ])));
}

class DrawerItem extends StatelessWidget {
  const DrawerItem(
      {super.key, required this.icon, required this.label, this.onTap});
  final String icon, label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => ListTile(
      leading: AppIcon(icon, color: AppTheme.ink, size: 22),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap ?? () => Navigator.pop(context));
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

/// Animated Qenbel Technologies branding badge
class QenbelBrandBadge extends StatefulWidget {
  const QenbelBrandBadge({super.key});

  @override
  State<QenbelBrandBadge> createState() => _QenbelBrandBadgeState();
}

class _QenbelBrandBadgeState extends State<QenbelBrandBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBF9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE5E1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF007F63), Color(0xFF267AF4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33007F63),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  )
                ],
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/sparkle.svg',
                  width: 14,
                  height: 14,
                  colorFilter:
                      const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'A PRODUCT OF',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppTheme.muted,
                ),
              ),
              Text(
                'Qenbel Technologies',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.ink,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
