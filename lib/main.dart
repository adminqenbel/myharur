import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import 'services/supabase_service.dart';
import 'l10n/translations.dart';
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
import 'features/community_hub_page.dart';
import 'features/notifications_page.dart';
import 'features/report_abuse_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  AuthService.init();
  runApp(const MyHarurApp());
}

class MyHarurApp extends StatelessWidget {
  const MyHarurApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AuthNotifier.instance, LanguageNotifier.instance]),
      builder: (context, _) {
        return MaterialApp(
          title: 'MyHarur',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: kIsWeb
              ? const WebDownloadLandingPage()
              : (AuthService.isAuthenticated ? const TownShell() : const TownOnboardingFlowPage()),
        );
      },
    );
  }
}

/// Dedicated web landing page displaying the APK download portal and town overview.
class WebDownloadLandingPage extends StatelessWidget {
  const WebDownloadLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B0A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF121C19).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFF007AFF).withValues(alpha: 0.25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 48,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: const Color(0xFF007AFF).withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Color(0xFF007AFF), size: 8),
                        SizedBox(width: 8),
                        Text(
                          'OFFICIAL ANDROID RELEASE',
                          style: TextStyle(
                            color: Color(0xFF007AFF),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'MyHarur App',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'The trusted digital-town app for Harur & Dharmapuri district, Tamil Nadu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  // Meta pills
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: const [
                      _MetaCard(label: 'VERSION', value: 'v0.2.0 (Latest)'),
                      _MetaCard(label: 'PACKAGE', value: 'Universal APK'),
                      _MetaCard(label: 'COMPATIBILITY', value: 'Android 6.0+'),
                      _MetaCard(label: 'SECURITY', value: '✓ Verified Build'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Download button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        foregroundColor: const Color(0xFF070B0A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 6,
                      ),
                      icon: const Icon(Icons.download_for_offline_rounded, size: 24),
                      label: const Text(
                        'DOWNLOAD OFFICIAL APK',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.3),
                      ),
                      onPressed: () => launchAppUrl('https://github.com/adminqenbel/myharur/releases/latest/download/myharur.apk'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Launch Interactive Web App Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF007AFF),
                        side: const BorderSide(color: Color(0xFF007AFF), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.open_in_browser_rounded, size: 20),
                      label: const Text(
                        'Launch Interactive Town Hub (Web)',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => AuthService.isAuthenticated ? const TownShell() : const TownOnboardingFlowPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF8E8E93)),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('Browse All Releases on GitHub ↗', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    onPressed: () => launchAppUrl('https://github.com/adminqenbel/myharur/releases'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  final String label;
  final String value;
  const _MetaCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class AppTheme {
  static const ink = Color(0xFF1C1C1E);
  static const muted = Color(0xFF8E8E93);
  static const mist = Color(0xFFF2F2F7);
  static const line = Color(0xFFE5E5EA);
  static const appleBlue = Color(0xFF007AFF);
  static const appleBlueLight = Color(0xFFEBF5FF);
  static const appleBlueDark = Color(0xFF0056B3);
  static const green = Color(0xFF007AFF); // Apple Blue primary brand
  static const mint = Color(0xFF007AFF);
  static const red = Color(0xFFFF3B30); // Apple System Red
  static const blue = Color(0xFF007AFF);
  static const amber = Color(0xFFFF9500); // Apple System Orange
  static const indigo = Color(0xFF5856D6); // Apple System Indigo

  static final light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF8F9FB),
    colorScheme: ColorScheme.fromSeed(
      seedColor: appleBlue,
      brightness: Brightness.light,
      surface: Colors.white,
    ),
    textTheme: const TextTheme(
      displaySmall: TextStyle(fontSize: 30, height: 1.1, fontWeight: FontWeight.w800, color: ink, letterSpacing: -0.6),
      headlineSmall: TextStyle(fontSize: 22, height: 1.2, fontWeight: FontWeight.w800, color: ink, letterSpacing: -0.4),
      titleLarge: TextStyle(fontSize: 18, height: 1.2, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.3),
      titleMedium: TextStyle(fontSize: 15, height: 1.2, fontWeight: FontWeight.w600, color: ink, letterSpacing: -0.2),
      bodyLarge: TextStyle(fontSize: 15, height: 1.35, color: ink),
      bodyMedium: TextStyle(fontSize: 13, height: 1.35, color: muted),
      labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: -0.1),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = kIsWeb && screenWidth > 720;

    final scaffold = Scaffold(
      drawer: const TownDrawer(),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeInOutCubic,
          switchOutCurve: Curves.easeInOutCubic,
          child: KeyedSubtree(
            key: ValueKey<int>(selected),
            child: pages[selected],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 68,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  border: Border.all(color: const Color(0xFF007AFF).withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: List.generate(labels.length, (index) {
                    final active = selected == index;
                    return Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(26),
                        onTap: () => setState(() => selected = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: active ? const Color(0xFF007AFF) : Colors.transparent,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF007AFF).withValues(alpha: 0.28),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppIcon(
                                icons[index],
                                color: active ? Colors.white : AppTheme.muted,
                                size: 19,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tr(labels[index]),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                                  color: active ? Colors.white : AppTheme.ink,
                                  letterSpacing: -0.2,
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

    if (!isWide) {
      return scaffold;
    }

    return Container(
      color: const Color(0xFFEBF1EE),
      child: Center(
        child: Container(
          width: 540,
          margin: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE5E5EA), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1C1C1E).withValues(alpha: 0.08),
                blurRadius: 36,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: scaffold,
        ),
      ),
    );
  }
}

Future<void> launchAppUrl(String url) async {
  try {
    final uri = Uri.parse(url);
    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
  } catch (e) {
    debugPrint('Could not launch URL: $url error: $e');
  }
}

// ==============================================================================
// HOME PAGE & TOWN DASHBOARD
// ==============================================================================
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = AuthService.currentProfile;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TownHeader(showSearch: true),
                const SizedBox(height: 16),

                // Greeting & Location
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${tr("Vanakkam")}, ${profile.fullName.split(' ').first}',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93), fontWeight: FontWeight.w700),
                          ),
                          Text(
                            tr('Harur Digital Town'),
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E), letterSpacing: -0.5),
                          ),
                        ],
                      ),
                    ),
                    const LocationPill(),
                  ],
                ),

                const SizedBox(height: 16),

                // Holographic MMID Quick Pass Card (Tappable to View Full Digital ID)
                _buildMmidQuickCard(context, profile),

                const SizedBox(height: 18),

                // Live Town Announcements Ticker
                _buildAnnouncementsTicker(context),

                const SizedBox(height: 22),

                // Digital Services Hub Grid (12 Modules)
                SectionHeader(label: tr('DIGITAL SERVICES & BAZAAR'), action: 'All Modules'),
                const SizedBox(height: 12),
                const TownServicesGrid(),

                const SizedBox(height: 22),

                // Weather & Agricultural Advisory Hub
                SectionHeader(label: tr('LIVE WEATHER & AGRI ADVISORY')),
                const SizedBox(height: 12),
                const WeatherCards(),

                const SizedBox(height: 22),

                // Featured Local News Card
                const SectionHeader(label: 'HARUR TOWN PULSE & UPDATES', action: 'Read all'),
                const SizedBox(height: 12),
                const FeaturedNewsCard(),

                const SizedBox(height: 22),

                // Emergency SOS Hotlines Quick Strip
                SectionHeader(label: tr('24/7 EMERGENCY HELPLINES')),
                const SizedBox(height: 12),
                _buildEmergencyHotlinesStrip(context),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMmidQuickCard(BuildContext context, UserProfile profile) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuthPage())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF007AFF).withValues(alpha: 0.28),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
              ),
              child: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        profile.fullName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.3),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          profile.primaryRoleTitle.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'MMID: ${profile.mmid} • ${profile.bloodGroup}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementsTicker(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign_rounded, color: Color(0xFFD97706), size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Morappur - Harur Rail Survey approved • Harur Drinking Water Scheme sanctioned',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
            ),
          ),
          InkWell(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewsHubPage())),
            child: const Text('View', style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.w900, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyHotlinesStrip(BuildContext context) {
    return Row(
      children: [
        _buildHotlineCard(tr('Ambulance'), '108', Icons.medical_services_rounded, const Color(0xFFE44545)),
        const SizedBox(width: 8),
        _buildHotlineCard(tr('Police Control'), '04346-222100', Icons.local_police_rounded, const Color(0xFF267AF4)),
        const SizedBox(width: 8),
        _buildHotlineCard(tr('Fire Station'), '101', Icons.local_fire_department_rounded, const Color(0xFFF59E0B)),
      ],
    );
  }

  Widget _buildHotlineCard(String label, String number, IconData icon, Color color) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => launchAppUrl('tel:$number'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
              const SizedBox(height: 2),
              Text(number, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E))),
            ],
          ),
        ),
      ),
    );
  }
}

class TownHeader extends StatelessWidget {
  const TownHeader({super.key, required this.showSearch});
  final bool showSearch;

  @override
  Widget build(BuildContext context) {
    final profile = AuthService.currentProfile;
    final isTamil = LanguageNotifier.instance.isTamil;

    return Row(
      children: [
        Builder(
          builder: (context) => RoundIconButton(
            icon: 'menu',
            onTap: () => Scaffold.of(context).openDrawer(),
          ),
        ),
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
                Text('myharur', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -.7)),
                Text('digital town', style: TextStyle(fontSize: 9, color: AppTheme.muted, letterSpacing: 1.2, fontWeight: FontWeight.w800)),
              ],
            ),
          ],
        ),
        const Spacer(),
        // Language Switcher (EN / தமிழ்)
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => LanguageNotifier.instance.toggleLanguage(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEBF5FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF9DD8C5)),
            ),
            child: Text(
              isTamil ? 'தமிழ்' : 'EN',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF007AFF)),
            ),
          ),
        ),
        const SizedBox(width: 6),
        // Notifications Bell Button
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsPage())),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E5EA)),
            ),
            child: const Center(
              child: Icon(Icons.notifications_outlined, size: 18, color: Color(0xFF1C1C1E)),
            ),
          ),
        ),
        const SizedBox(width: 6),
        // Quick SOS Button
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmergencySosPage())),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFECEB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF8C9C5)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emergency_rounded, size: 15, color: Color(0xFFE44545)),
                SizedBox(width: 3),
                Text('SOS', style: TextStyle(color: Color(0xFFE44545), fontWeight: FontWeight.w900, fontSize: 10)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        // User Profile Avatar Button
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuthPage())),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEBF5FF),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF007AFF), width: 1.5),
            ),
            child: Center(
              child: Text(
                profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : 'H',
                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF007AFF), fontSize: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class LocationPill extends StatelessWidget {
  const LocationPill({super.key});

  @override
  Widget build(BuildContext context) {
    final locationName = AuthService.currentProfile.wardLocality;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LocationSelectionPage())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E5EA)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on_rounded, color: Color(0xFF007AFF), size: 14),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Text(
                locationName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF1C1C1E)),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF8E8E93)),
          ],
        ),
      ),
    );
  }
}

class TownServicesGrid extends StatelessWidget {
  const TownServicesGrid({super.key});

  static const services = [
    ('store', 'Local Shops', 'Bazaar & Stores', Color(0xFF007AFF)),
    ('briefcase', 'Job Portal', 'Work & Wages', Color(0xFF267AF4)),
    ('bag', 'Mandi Rates', 'Agri & Crop Rates', Color(0xFFF59E0B)),
    ('compass', 'Bus Timings', 'Routes & Transit', Color(0xFF10B981)),
    ('alert', 'Emergency SOS', '108 & Police Hub', Color(0xFFE44545)),
    ('chat', 'Community Hub', 'Polls & Town Hall', Color(0xFF8B5CF6)),
    ('heart', 'Blood Donors', 'Lifeline Network', Color(0xFFEC4899)),
    ('shield', 'Grievances', 'Municipal Helpdesk', Color(0xFF06B6D4)),
    ('bag', 'Marketplace', 'Buy, Sell, Rent', Color(0xFF14B8A6)),
    ('calendar', 'Town Events', 'Festivals & Meets', Color(0xFFF97316)),
    ('award', 'Leaderboard', 'Citizen Honours', Color(0xFFEAB308)),
    ('news', 'Govt Orders', 'Official Circulars', Color(0xFF8E8E93)),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.95,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, i) {
        final s = services[i];
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openServicePage(context, s.$1, s.$2),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5E5EA)),
              boxShadow: const [
                BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 3)),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: s.$4.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: AppIcon(s.$1, color: s.$4, size: 20),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tr(s.$2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF1C1C1E)),
                ),
                const SizedBox(height: 2),
                Text(
                  s.$3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9, color: Color(0xFF8E8E93), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openServicePage(BuildContext context, String icon, String title) {
    Widget page;
    switch (title) {
      case 'Local Shops':
        page = const ShopsPage();
        break;
      case 'Job Portal':
        page = const JobsPage();
        break;
      case 'Mandi Rates':
        page = const AgriMandiPage();
        break;
      case 'Bus Timings':
        page = const BusRoutesPage();
        break;
      case 'Emergency SOS':
        page = const EmergencySosPage();
        break;
      case 'Community Hub':
        page = const CommunityHubPage();
        break;
      case 'Blood Donors':
        page = const BloodDonorsPage();
        break;
      case 'Grievances':
        page = const GrievanceSubmissionPage();
        break;
      case 'Marketplace':
        page = const MarketplacePage();
        break;
      case 'Town Events':
        page = const EventsPage();
        break;
      case 'Leaderboard':
        page = const RankingsPage();
        break;
      case 'Govt Orders':
        page = const GovtOrdersPage();
        break;
      default:
        page = const NewsHubPage();
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

class CategoryRail extends StatelessWidget {
  const CategoryRail({super.key});
  static const items = [
    ('store', 'Shops'),
    ('briefcase', 'Jobs'),
    ('bag', 'Mandi'),
    ('compass', 'Bus'),
    ('heart', 'SOS 108'),
    ('chat', 'Town Chat'),
    ('calendar', 'Events'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 94,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return SizedBox(
            width: 68,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _openCategory(context, item.$1),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: index == 0 ? const Color(0xFFEBF5FF) : const Color(0xFFF2F2F7),
                      border: Border.all(color: index == 0 ? const Color(0xFF007AFF) : const Color(0xFFE5E5EA)),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: AppIcon(item.$1, color: index == 0 ? AppTheme.green : AppTheme.ink, size: 24),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: index == 0 ? FontWeight.w900 : FontWeight.w700,
                      color: index == 0 ? AppTheme.green : AppTheme.ink,
                    ),
                  ),
                ],
              ),
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
    case 'store':
      page = const ShopsPage();
      break;
    case 'briefcase':
      page = const JobsPage();
      break;
    case 'bag':
      page = const MarketplacePage();
      break;
    case 'compass':
      page = const BusRoutesPage();
      break;
    case 'heart':
      page = const EmergencySosPage();
      break;
    case 'chat':
      page = const CommunityHubPage();
      break;
    case 'calendar':
      page = const EventsPage();
      break;
    default:
      page = const NewsHubPage();
  }
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}

class FeaturedNewsCard extends StatelessWidget {
  const FeaturedNewsCard({super.key});
  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewsHubPage())),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppIcon('news', color: Color(0xFFD97706), size: 20),
                  SizedBox(width: 8),
                  Text('OFFICIAL DISPATCH', style: TextStyle(color: Color(0xFFD97706), fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w900)),
                  Spacer(),
                  Icon(Icons.arrow_forward_rounded, color: Color(0xFF92400E), size: 18),
                ],
              ),
              SizedBox(height: 12),
              Text(
                'Southern Railway inspects Harur-Morappur broad gauge corridor',
                style: TextStyle(fontSize: 16, height: 1.25, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E)),
              ),
              SizedBox(height: 6),
              Text(
                'High-level inspection completed for 36 km route linking Dharmapuri district with Salem main line.',
                style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12, height: 1.35),
              ),
            ],
          ),
        ),
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
              final temp = snapshot.hasData ? "${(snapshot.data!['temperature_c'] as num).round()}°C" : "32°C";
              final condition = snapshot.hasData ? (snapshot.data!['condition'] as String) : "Partly Cloudy";
              return WeatherCard(
                place: 'Harur Taluk',
                temperature: temp,
                caption: condition,
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: WeatherService.getLatestSnapshot('Dharmapuri'),
            builder: (context, snapshot) {
              final temp = snapshot.hasData ? "${(snapshot.data!['temperature_c'] as num).round()}°C" : "33°C";
              final condition = snapshot.hasData ? (snapshot.data!['condition'] as String) : "Sunny & Breeze";
              return WeatherCard(
                place: 'Dharmapuri HQ',
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
  const WeatherCard({super.key, required this.place, required this.temperature, required this.caption});
  final String place, temperature, caption;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WeatherHubPage())),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E5EA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppIcon('cloud', color: AppTheme.blue, size: 22),
              const SizedBox(height: 12),
              Text(temperature, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E))),
              Text(place, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF1C1C1E))),
              const SizedBox(height: 2),
              Text(caption, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
            ],
          ),
        ),
      );
}

// ==============================================================================
// EXPLORE PAGE
// ==============================================================================
class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  static const cards = [
    ('store', 'Local Shops', 'Harur Bazaar & merchants'),
    ('briefcase', 'Jobs Portal', 'Daily wage & local hiring'),
    ('bag', 'Marketplace', 'Buy, sell, agri tools'),
    ('calendar', 'Events', 'Cultural festivals & sports'),
    ('award', 'Rankings', 'Leaderboard & donations'),
    ('heart', 'Emergency 108', 'Lifeline & police control'),
  ];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TownHeader(showSearch: true),
                const SizedBox(height: 24),
                Text(tr('Explore'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E), letterSpacing: -0.5)),
                const SizedBox(height: 4),
                const Text('Discover everything happening across Harur & Dharmapuri.', style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
                const SizedBox(height: 20),
                GridView.builder(
                  itemCount: cards.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.05,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        final Widget page = switch (card.$1) {
                          'store' => const ShopsPage(),
                          'briefcase' => const JobsPage(),
                          'bag' => const MarketplacePage(),
                          'calendar' => const EventsPage(),
                          'award' => const RankingsPage(),
                          'heart' => const EmergencySosPage(),
                          _ => const HomePage(),
                        };
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE5E5EA)),
                          boxShadow: const [
                            BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEBF5FF),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: AppIcon(card.$1, color: AppTheme.green, size: 22),
                              ),
                            ),
                            const Spacer(),
                            Text(card.$2, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E))),
                            const SizedBox(height: 2),
                            Text(card.$3, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
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

// ==============================================================================
// ALERTS & NOTIFICATIONS PAGE
// ==============================================================================
class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TownHeader(showSearch: false),
          const SizedBox(height: 24),
          Text(tr('Alerts'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E), letterSpacing: -0.5)),
          const SizedBox(height: 4),
          const Text('Emergency dispatch & verified municipal announcements.', style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
          const SizedBox(height: 20),

          // Primary Emergency Action Box
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmergencySosPage())),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFECEB),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF8C9C5)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppIcon('alert', color: AppTheme.red, size: 26),
                      Spacer(),
                      Icon(Icons.arrow_forward_rounded, color: AppTheme.red),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text('Need Immediate Assistance?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E))),
                  SizedBox(height: 4),
                  Text('Trigger instant SOS broadcast to nearest Harur responders & 108 ambulance.', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          const SectionHeader(label: 'GOVERNMENT ORDERS & OFFICIAL CIRCULARS'),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GovtOrdersPage())),
            child: const SoftCard(
              child: Row(
                children: [
                  AppIcon('news', color: AppTheme.blue, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Browse Government Orders (G.O.)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                        SizedBox(height: 2),
                        Text('Published by verified Dharmapuri district officials.', style: TextStyle(fontSize: 11, color: AppTheme.muted)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GrievanceSubmissionPage())),
            child: const SoftCard(
              child: Row(
                children: [
                  AppIcon('shield', color: AppTheme.green, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Track Civic Grievances', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                        SizedBox(height: 2),
                        Text('Submit street, water, or road issues to town officials.', style: TextStyle(fontSize: 11, color: AppTheme.muted)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// ACCOUNT & RESIDENT PROFILE PAGE
// ==============================================================================
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = AuthService.currentProfile;
    final isLoggedIn = AuthService.isAuthenticated;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TownHeader(showSearch: false),
          const SizedBox(height: 20),

          // Profile Header Row
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF5FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF007AFF), width: 2),
                ),
                child: Center(
                  child: Text(
                    profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : 'H',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF007AFF)),
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
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E)),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF007AFF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            profile.primaryRoleTitle.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'MMID: ${profile.mmid}',
                          style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Manage Profile & Security
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuthPage())),
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
                          isLoggedIn ? 'Manage Digital Pass & Security' : 'Sign In / Register Digital Pass',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isLoggedIn ? '${profile.wardLocality} • Blood Group: ${profile.bloodGroup}' : 'Google OAuth, Password & MMID creation',
                          style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          const SectionHeader(label: 'TOWN SERVICES & TOOLS'),
          const SizedBox(height: 10),
          const AccountRows(),

          const SizedBox(height: 24),
          const SectionHeader(label: 'COMMUNITY MODERATION & CIVIC SAFETY'),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportAbusePage())),
            child: const SoftCard(
              child: Row(
                children: [
                  Icon(Icons.flag_rounded, color: Color(0xFFE44545), size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Report Abuse, Scams or False Content', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        SizedBox(height: 2),
                        Text('Protect Harur town by reporting violations to moderators.', style: TextStyle(fontSize: 11, color: AppTheme.muted)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          const SectionHeader(label: 'GOVERNANCE & ADMIN ACCESS'),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminDashboardPage())),
            child: const SoftCard(
              child: Row(
                children: [
                  AppIcon('shield', color: AppTheme.red, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SuperAdmin Governance Console', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        SizedBox(height: 2),
                        Text('Passkey moderation, consensus & municipal ledger', style: TextStyle(fontSize: 11, color: AppTheme.muted)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ==============================================================================
// SHARED REUSABLE COMPONENTS
// ==============================================================================
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.label, this.action});
  final String label;
  final String? action;
  @override
  Widget build(BuildContext context) => Row(children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF8E8E93),
                letterSpacing: 1.1)),
        const Spacer(),
        if (action != null)
          Text(action!,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.green)),
      ]);
}

class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E5EA)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ]),
      child: child);
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.onTap});
  final String icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E5EA))),
          child: Center(child: AppIcon(icon, color: AppTheme.ink, size: 19))));
}

class AppIcon extends StatelessWidget {
  const AppIcon(this.name, {super.key, required this.color, required this.size});
  final String name;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => SvgPicture.asset(
      'assets/icons/$name.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn));
}

class AccountRows extends StatelessWidget {
  const AccountRows({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRow(context, 'chat', 'Community Hub & Polls', 'Citizen voting & discussions', const CommunityHubPage()),
        const SizedBox(height: 8),
        _buildRow(context, 'bag', 'My Harur Marketplace Listings', 'Manage classified items', const MarketplacePage()),
        const SizedBox(height: 8),
        _buildRow(context, 'briefcase', 'My Job Postings & Resumes', 'Manage job requirements', const JobsPage()),
        const SizedBox(height: 8),
        _buildRow(context, 'store', 'My Registered Shops', 'Harur merchant directory', const ShopsPage()),
        const SizedBox(height: 8),
        _buildRow(context, 'calendar', 'My Registered Events', 'Temple festivals & meetings', const EventsPage()),
      ],
    );
  }

  Widget _buildRow(BuildContext context, String icon, String label, String detail, Widget destination) => InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => destination)),
        child: SoftCard(
          child: Row(
            children: [
              AppIcon(icon, color: AppTheme.green, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(detail, style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      );
}

// ==============================================================================
// TOWN DRAWER (NO IN-APP DOWNLOAD APK ADS)
// ==============================================================================
class TownDrawer extends StatelessWidget {
  const TownDrawer({super.key});

  @override
  Widget build(BuildContext context) => Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  children: [
                    SvgPicture.asset('assets/brand/myharur_icon.svg', width: 40, height: 40),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('myharur', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        Text('Your Connected Town', style: TextStyle(color: AppTheme.muted, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              DrawerItem(
                icon: 'chat',
                label: 'Community Hub & Citizen Polls',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CommunityHubPage()));
                },
              ),
              DrawerItem(
                icon: 'chat',
                label: 'Town Hall & AI Chat',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TownChatPage()));
                },
              ),
              DrawerItem(
                icon: 'news',
                label: 'Official Government Orders',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GovtOrdersPage()));
                },
              ),
              DrawerItem(
                icon: 'store',
                label: 'Local Shops & Bazaar',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShopsPage()));
                },
              ),
              DrawerItem(
                icon: 'compass',
                label: 'Harur Bus Routes & Timings',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BusRoutesPage()));
                },
              ),
              DrawerItem(
                icon: 'bag',
                label: 'Agri Mandi Daily Rates',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AgriMandiPage()));
                },
              ),
              DrawerItem(
                icon: 'heart',
                label: 'Blood Donors Directory',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BloodDonorsPage()));
                },
              ),
              DrawerItem(
                icon: 'shield',
                label: 'Submit Civic Grievance',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GrievanceSubmissionPage()));
                },
              ),
              DrawerItem(
                icon: 'calendar',
                label: 'Events & Festivals',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EventsPage()));
                },
              ),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminDashboardPage()));
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF5FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF9DD8C5)),
                  ),
                  child: const Row(
                    children: [
                      AppIcon('shield', color: AppTheme.green, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SuperAdmin Console', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.green)),
                            Text('Passkey protected governance', style: TextStyle(fontSize: 10, color: AppTheme.muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
}

class DrawerItem extends StatelessWidget {
  const DrawerItem({super.key, required this.icon, required this.label, required this.onTap});
  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: AppIcon(icon, color: AppTheme.green, size: 20),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1C1C1E))),
        onTap: onTap,
        dense: true,
      );
}
