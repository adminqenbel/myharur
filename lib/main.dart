import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import 'services/supabase_service.dart';
import 'l10n/translations.dart';
import 'widgets/glass_components.dart';
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
                border: Border.all(color: const Color(0xFF234149).withValues(alpha: 0.35)),
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
                      color: const Color(0xFF234149).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: const Color(0xFF8EB7C7).withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Color(0xFF8EB7C7), size: 8),
                        SizedBox(width: 8),
                        Text(
                          'OFFICIAL ANDROID RELEASE',
                          style: TextStyle(
                            color: Color(0xFF8EB7C7),
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
                      _MetaCard(label: 'VERSION', value: 'v0.3.0 (Latest)'),
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
                        backgroundColor: const Color(0xFF234149),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 6,
                      ),
                      icon: const Icon(Icons.download_for_offline_rounded, size: 24),
                      label: const Text(
                        'Download Universal APK (Direct)',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      onPressed: () => launchAppUrl('/myharur.apk'),
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
  static const petrolDark = Color(0xFF234149);
  static const petrolMedium = Color(0xFF2B4C56);
  static const icePastel = Color(0xFFE2EDF2);
  static const icePastelBorder = Color(0xFFD4E3EA);
  static const ink = Color(0xFF16272E);
  static const muted = Color(0xFF6A828B);
  static const mist = Color(0xFFF3F7F9);
  static const line = Color(0xFFE3EDF2);
  static const green = Color(0xFF234149); // Petrol Dark primary brand
  static const mint = Color(0xFF8EB7C7);
  static const red = Color(0xFFE44545);
  static const blue = Color(0xFF247BA0);
  static const amber = Color(0xFFF59E0B);
  static const indigo = Color(0xFF3B5998);

  static final light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF6F9FA),
    colorScheme: ColorScheme.fromSeed(
      seedColor: petrolDark,
      brightness: Brightness.light,
      surface: Colors.white,
      primary: petrolDark,
      secondary: icePastel,
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
      body: AtmosphericBackground(
        child: SafeArea(
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
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
          child: Container(
            height: 66,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFF234149),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: const Color(0xFF345660), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF234149).withValues(alpha: 0.35),
                  blurRadius: 24,
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
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 10,
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
                            color: active ? const Color(0xFF234149) : const Color(0xFF90ACB6),
                            size: 19,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tr(labels[index]),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                              color: active ? const Color(0xFF234149) : const Color(0xFF90ACB6),
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
    );

    if (!isWide) {
      return scaffold;
    }

    return Container(
      color: const Color(0xFFE2EDF2),
      child: Center(
        child: Container(
          width: 540,
          margin: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFD4E3EA), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF234149).withValues(alpha: 0.12),
                blurRadius: 40,
                offset: const Offset(0, 14),
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
// HOME PAGE & TOWN DASHBOARD (BENTO GRID AESTHETIC)
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

                // Top Avatar / Category Rail (HAIIE DOMES style from reference image)
                const CategoryAvatarRail(),
                const SizedBox(height: 20),

                // Section: Bento Services Grid
                const SectionHeader(label: 'SERVICES & MMID PASS', action: 'All Modules'),
                const SizedBox(height: 12),

                // Hero Holographic MMID Pass Bento Card (Dark Petrol)
                _buildMmidHeroBentoCard(context, profile),
                const SizedBox(height: 14),

                // Asymmetric Bento Grid
                _buildAsymmetricBentoGrid(context),
                const SizedBox(height: 20),

                // Live Town Announcements Ticker
                const SectionHeader(label: 'TOWN PULSE & DISPATCH'),
                const SizedBox(height: 10),
                _buildAnnouncementsTicker(context),
                const SizedBox(height: 20),

                // Live Weather & Agro Advisory Hub
                const SectionHeader(label: 'LIVE WEATHER & AGRO ADVISORY', action: 'Harur & HQ'),
                const SizedBox(height: 10),
                const WeatherCards(),
                const SizedBox(height: 20),

                // Emergency SOS Hotlines Quick Strip
                SectionHeader(label: tr('24/7 EMERGENCY HELPLINES')),
                const SizedBox(height: 10),
                _buildEmergencyHotlinesStrip(context),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMmidHeroBentoCard(BuildContext context, UserProfile profile) {
    return BentoCard(
      variant: BentoCardVariant.darkPetrol,
      borderRadius: 28,
      padding: const EdgeInsets.all(20),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuthPage())),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF8EB7C7).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: const Color(0xFF8EB7C7).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Color(0xFF8EB7C7), size: 12),
                    const SizedBox(width: 5),
                    Text(
                      'VERIFIED DIGITAL MMID PASS'.toUpperCase(),
                      style: const TextStyle(color: Color(0xFF8EB7C7), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: const Center(
                  child: Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            profile.fullName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'MMID: ${profile.mmid}',
                style: const TextStyle(color: Color(0xFFB5D4DF), fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  profile.primaryRoleTitle.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                ),
              ),
              const Spacer(),
              Text(
                profile.bloodGroup,
                style: const TextStyle(color: Color(0xFF8EB7C7), fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAsymmetricBentoGrid(BuildContext context) {
    return Column(
      children: [
        // Row 1: Large Mandi card (left) + Bus Routes (right)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: BentoCard(
                variant: BentoCardVariant.pastel,
                borderRadius: 24,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AgriMandiPage())),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF234149).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(child: AppIcon('bag', color: Color(0xFF234149), size: 20)),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF234149),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('₹5,400/Q', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text('Mandi APMC Rates', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF16272E))),
                    const SizedBox(height: 2),
                    const Text('Daily paddy, turmeric & cotton auctions in Harur.', style: TextStyle(fontSize: 11, color: Color(0xFF6A828B), height: 1.3)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: BentoCard(
                variant: BentoCardVariant.elevatedWhite,
                borderRadius: 24,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BusRoutesPage())),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF247BA0).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: AppIcon('compass', color: Color(0xFF247BA0), size: 20)),
                    ),
                    const SizedBox(height: 18),
                    const Text('Bus Routes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF16272E))),
                    const SizedBox(height: 2),
                    const Text('TNSTC Harur live timings', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Color(0xFF6A828B))),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 2: 3 Square Bento Cards (Shops, Jobs, SOS)
        Row(
          children: [
            Expanded(
              child: BentoCard(
                variant: BentoCardVariant.pastel,
                borderRadius: 22,
                padding: const EdgeInsets.all(14),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShopsPage())),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF234149).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: AppIcon('store', color: Color(0xFF234149), size: 18)),
                    ),
                    const SizedBox(height: 14),
                    const Text('Local Shops', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF16272E))),
                    const SizedBox(height: 1),
                    const Text('Bazaar directory', style: TextStyle(fontSize: 10, color: Color(0xFF6A828B))),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BentoCard(
                variant: BentoCardVariant.elevatedWhite,
                borderRadius: 22,
                padding: const EdgeInsets.all(14),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const JobsPage())),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF267AF4).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: AppIcon('briefcase', color: Color(0xFF267AF4), size: 18)),
                    ),
                    const SizedBox(height: 14),
                    const Text('Job Portal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF16272E))),
                    const SizedBox(height: 1),
                    const Text('Work & wages', style: TextStyle(fontSize: 10, color: Color(0xFF6A828B))),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BentoCard(
                variant: BentoCardVariant.pastel,
                borderRadius: 22,
                padding: const EdgeInsets.all(14),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CommunityHubPage())),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: AppIcon('chat', color: Color(0xFF8B5CF6), size: 18)),
                    ),
                    const SizedBox(height: 14),
                    const Text('Town Hall', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF16272E))),
                    const SizedBox(height: 1),
                    const Text('Citizen polls', style: TextStyle(fontSize: 10, color: Color(0xFF6A828B))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnnouncementsTicker(BuildContext context) {
    return BentoCard(
      variant: BentoCardVariant.elevatedWhite,
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewsHubPage())),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.campaign_rounded, color: Color(0xFFD97706), size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Harur-Morappur Broad Gauge inspection completed • Drinking Water Scheme sanctioned',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF16272E)),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF6A828B)),
        ],
      ),
    );
  }

  Widget _buildEmergencyHotlinesStrip(BuildContext context) {
    return Row(
      children: [
        _buildHotlineCard(tr('Ambulance'), '108', Icons.medical_services_rounded, const Color(0xFFE44545)),
        const SizedBox(width: 8),
        _buildHotlineCard(tr('Police Control'), '04346-222100', Icons.local_police_rounded, const Color(0xFF247BA0)),
        const SizedBox(width: 8),
        _buildHotlineCard(tr('Fire Station'), '101', Icons.local_fire_department_rounded, const Color(0xFFF59E0B)),
      ],
    );
  }

  Widget _buildHotlineCard(String label, String number, IconData icon, Color color) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => launchAppUrl('tel:$number'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
              const SizedBox(height: 2),
              Text(number, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF16272E))),
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
                Text('myharur', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -.7, color: Color(0xFF16272E))),
                Text('digital town', style: TextStyle(fontSize: 9, color: Color(0xFF6A828B), letterSpacing: 1.2, fontWeight: FontWeight.w800)),
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
              color: const Color(0xFFE2EDF2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD4E3EA)),
            ),
            child: Text(
              isTamil ? 'தமிழ்' : 'EN',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF234149)),
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
              color: const Color(0xFFE2EDF2),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD4E3EA)),
            ),
            child: const Center(
              child: Icon(Icons.notifications_outlined, size: 18, color: Color(0xFF16272E)),
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
              color: const Color(0xFF234149),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF345660), width: 1.5),
            ),
            child: Center(
              child: Text(
                profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : 'H',
                style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 13),
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
          color: const Color(0xFFE2EDF2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD4E3EA)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on_rounded, color: Color(0xFF234149), size: 14),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Text(
                locationName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF16272E)),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF6A828B)),
          ],
        ),
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
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WeatherHubPage())),
        child: BentoCard(
          variant: BentoCardVariant.elevatedWhite,
          borderRadius: 22,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppIcon('cloud', color: Color(0xFF247BA0), size: 22),
              const SizedBox(height: 12),
              Text(temperature, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF16272E))),
              Text(place, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF16272E))),
              const SizedBox(height: 2),
              Text(caption, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF6A828B))),
            ],
          ),
        ),
      );
}

/// Category & Avatar Scroll Rail (Screen 2 HAIIE DOMES style)
class CategoryAvatarRail extends StatelessWidget {
  const CategoryAvatarRail({super.key});

  static const items = [
    ('store', 'Bazaar', 'Shops'),
    ('bag', 'Mandi', 'Agri Rates'),
    ('briefcase', 'Jobs', 'Daily Wage'),
    ('compass', 'Transit', 'Bus Routes'),
    ('heart', 'Donors', 'Blood 108'),
    ('chat', 'Town Chat', 'Civic Polls'),
    ('calendar', 'Events', 'Festivals'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          final isFirst = index == 0;

          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _openCategory(context, item.$1),
            child: SizedBox(
              width: 62,
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isFirst ? const Color(0xFF234149) : const Color(0xFFE2EDF2),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isFirst ? const Color(0xFF345660) : const Color(0xFFD4E3EA),
                        width: 1.0,
                      ),
                      boxShadow: isFirst
                          ? [
                              BoxShadow(
                                color: const Color(0xFF234149).withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: AppIcon(
                        item.$1,
                        color: isFirst ? Colors.white : const Color(0xFF234149),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isFirst ? FontWeight.w900 : FontWeight.w700,
                      color: const Color(0xFF16272E),
                      letterSpacing: -0.2,
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

// ==============================================================================
// EXPLORE PAGE (SCREEN 3 AESTHETIC: SEARCH PILL, SQUIRCLE TILES, CLEAN LIST)
// ==============================================================================
class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  int selectedCategoryIndex = 0;
  final TextEditingController _searchCtrl = TextEditingController();

  final categoryTiles = [
    {'icon': 'store', 'label': 'Shops', 'sub': 'Bazaar'},
    {'icon': 'compass', 'label': 'Transit', 'sub': 'TNSTC'},
    {'icon': 'bag', 'label': 'Market', 'sub': 'Classified'},
  ];

  final exploreListItems = [
    {
      'title': 'Harur Town Municipal Drinking Water Scheme',
      'subtitle': 'Phase-2 pipeline laying underway near Theerthamalai road.',
      'category': 'Municipal Project',
      'icon': Icons.water_drop_rounded,
      'color': Color(0xFF247BA0),
    },
    {
      'title': 'Morappur - Harur Railway Junction Land Survey',
      'subtitle': 'Southern Railway survey team stationed at Harur Taluk Office.',
      'category': 'Transit & Rail',
      'icon': Icons.train_rounded,
      'color': Color(0xFF234149),
    },
    {
      'title': 'APMC Daily Agri Commodity Auction',
      'subtitle': 'Harur Regulated Market yard open for paddy, ragi, and maize.',
      'category': 'Agri Mandi',
      'icon': Icons.agriculture_rounded,
      'color': Color(0xFFF59E0B),
    },
    {
      'title': 'Theerthamalai Sacred Hill Temple Car Festival',
      'subtitle': 'Annual Masi Theertham festival preparations and special bus permits.',
      'category': 'Heritage & Event',
      'icon': Icons.temple_hindu_rounded,
      'color': Color(0xFF8B5CF6),
    },
    {
      'title': 'Harur Government Hospital Blood Bank Active Drive',
      'subtitle': 'Emergency call for O+ and B+ units with digital pass credit points.',
      'category': 'Emergency 108',
      'icon': Icons.favorite_rounded,
      'color': Color(0xFFE44545),
    },
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

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
                const TownHeader(showSearch: false),
                const SizedBox(height: 20),

                // Search Pill with Action Chip (matching Screen 3)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFD4E3EA), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF234149).withValues(alpha: 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: Color(0xFF6A828B), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF16272E)),
                          decoration: const InputDecoration(
                            hintText: 'Search shops, bus routes, schemes...',
                            hintStyle: TextStyle(color: Color(0xFF90ACB6), fontSize: 13),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF234149),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'SEARCH',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3 Prominent Squircle Category Tiles (Screen 3 style)
                Row(
                  children: [
                    SquircleTile(
                      icon: const AppIcon('store', color: Color(0xFF234149), size: 24),
                      label: 'Shops',
                      sublabel: 'Bazaar Hub',
                      isSelected: selectedCategoryIndex == 0,
                      onTap: () => setState(() => selectedCategoryIndex = 0),
                    ),
                    const SizedBox(width: 10),
                    SquircleTile(
                      icon: const Icon(Icons.arrow_upward_rounded, color: Color(0xFF247BA0), size: 24),
                      label: 'Transit',
                      sublabel: 'Bus Timings',
                      isSelected: selectedCategoryIndex == 1,
                      onTap: () => setState(() => selectedCategoryIndex = 1),
                    ),
                    const SizedBox(width: 10),
                    SquircleTile(
                      icon: const AppIcon('bag', color: Color(0xFF234149), size: 24),
                      label: 'Agri Mandi',
                      sublabel: 'Daily Crop',
                      isSelected: selectedCategoryIndex == 2,
                      onTap: () => setState(() => selectedCategoryIndex = 2),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Section: Notices & Updates
                const SectionHeader(label: 'NOTICES & VERIFIED UPDATES', action: 'Filter'),
                const SizedBox(height: 12),

                // Clean List Items in Squircle Containers (Screen 3 style)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: exploreListItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final item = exploreListItems[i];
                    return BentoCard(
                      variant: BentoCardVariant.elevatedWhite,
                      borderRadius: 20,
                      padding: const EdgeInsets.all(16),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewsHubPage())),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: (item['color'] as Color).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 20),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE2EDF2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        (item['category'] as String).toUpperCase(),
                                        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFF234149)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['title'] as String,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF16272E), height: 1.2),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['subtitle'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF6A828B)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, color: Color(0xFF90ACB6), size: 20),
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
          Text(tr('Alerts'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF16272E), letterSpacing: -0.5)),
          const SizedBox(height: 4),
          const Text('Emergency dispatch & verified municipal announcements.', style: TextStyle(fontSize: 13, color: Color(0xFF6A828B))),
          const SizedBox(height: 20),

          // Primary Emergency Action Box (Squircle Bento)
          BentoCard(
            variant: BentoCardVariant.elevatedWhite,
            borderRadius: 24,
            padding: const EdgeInsets.all(20),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmergencySosPage())),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE44545).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const AppIcon('alert', color: Color(0xFFE44545), size: 24),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE44545),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Text('24/7 SOS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Need Immediate Assistance?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF16272E))),
                const SizedBox(height: 4),
                const Text('Trigger instant SOS broadcast to nearest Harur responders & 108 ambulance.', style: TextStyle(color: Color(0xFF6A828B), fontSize: 12, height: 1.35)),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const SectionHeader(label: 'GOVERNMENT ORDERS & OFFICIAL CIRCULARS'),
          const SizedBox(height: 10),
          BentoCard(
            variant: BentoCardVariant.pastel,
            borderRadius: 20,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GovtOrdersPage())),
            child: const Row(
              children: [
                AppIcon('news', color: Color(0xFF247BA0), size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Browse Government Orders (G.O.)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF16272E))),
                      SizedBox(height: 2),
                      Text('Published by verified Dharmapuri district officials.', style: TextStyle(fontSize: 11, color: Color(0xFF6A828B))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Color(0xFF90ACB6)),
              ],
            ),
          ),

          const SizedBox(height: 12),
          BentoCard(
            variant: BentoCardVariant.elevatedWhite,
            borderRadius: 20,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GrievanceSubmissionPage())),
            child: const Row(
              children: [
                AppIcon('shield', color: Color(0xFF234149), size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Track Civic Grievances', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF16272E))),
                      SizedBox(height: 2),
                      Text('Submit street, water, or road issues to town officials.', style: TextStyle(fontSize: 11, color: Color(0xFF6A828B))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Color(0xFF90ACB6)),
              ],
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

          // Profile Header Row (Squircle Avatar)
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF234149),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF234149).withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : 'H',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
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
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFF16272E)),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF234149),
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
                          style: const TextStyle(color: Color(0xFF6A828B), fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Manage Profile & Security (Squircle Bento)
          BentoCard(
            variant: BentoCardVariant.darkPetrol,
            borderRadius: 22,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuthPage())),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const AppIcon('shield', color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLoggedIn ? 'Manage Digital Pass & Security' : 'Sign In / Register Digital Pass',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isLoggedIn ? '${profile.wardLocality} • Blood Group: ${profile.bloodGroup}' : 'Google OAuth, Password & MMID creation',
                        style: const TextStyle(fontSize: 11, color: Color(0xFFB5D4DF)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // System Health & Backend Diagnostics
          const _BackendHealthCard(),

          const SizedBox(height: 24),
          const SectionHeader(label: 'TOWN SERVICES & TOOLS'),
          const SizedBox(height: 10),
          const AccountRows(),

          const SizedBox(height: 24),
          const SectionHeader(label: 'COMMUNITY MODERATION & CIVIC SAFETY'),
          const SizedBox(height: 10),
          BentoCard(
            variant: BentoCardVariant.elevatedWhite,
            borderRadius: 20,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportAbusePage())),
            child: const Row(
              children: [
                Icon(Icons.flag_rounded, color: Color(0xFFE44545), size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Report Abuse, Scams or False Content', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF16272E))),
                      SizedBox(height: 2),
                      Text('Protect Harur town by reporting violations to moderators.', style: TextStyle(fontSize: 11, color: Color(0xFF6A828B))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Color(0xFF90ACB6)),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const SectionHeader(label: 'GOVERNANCE & ADMIN ACCESS'),
          const SizedBox(height: 10),
          BentoCard(
            variant: BentoCardVariant.pastel,
            borderRadius: 20,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminDashboardPage())),
            child: const Row(
              children: [
                AppIcon('shield', color: Color(0xFF234149), size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SuperAdmin Governance Console', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF16272E))),
                      SizedBox(height: 2),
                      Text('Passkey moderation, consensus & municipal ledger', style: TextStyle(fontSize: 11, color: Color(0xFF6A828B))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Color(0xFF90ACB6)),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// Backend & Database Diagnostics Card
class _BackendHealthCard extends StatefulWidget {
  const _BackendHealthCard();

  @override
  State<_BackendHealthCard> createState() => _BackendHealthCardState();
}

class _BackendHealthCardState extends State<_BackendHealthCard> {
  bool _isChecking = false;
  Map<String, dynamic>? _healthData;

  @override
  void initState() {
    super.initState();
    _checkHealth();
  }

  Future<void> _checkHealth() async {
    setState(() => _isChecking = true);
    final data = await BackendHealthService.verifyFullSystem();
    await KeepAliveService.pingServices();
    if (mounted) {
      setState(() {
        _healthData = data;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConfigured = SupabaseConfig.isConfigured;

    return BentoCard(
      variant: BentoCardVariant.elevatedWhite,
      borderRadius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isConfigured ? Icons.cloud_done_rounded : Icons.cloud_queue_rounded,
                color: isConfigured ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'BACKEND & DATABASE STATUS',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF16272E), letterSpacing: 0.8),
              ),
              const Spacer(),
              InkWell(
                onTap: _isChecking ? null : _checkHealth,
                child: _isChecking
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF247BA0)),
                          SizedBox(width: 2),
                          Text('Pulse', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF247BA0))),
                        ],
                      ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isConfigured
                ? '✓ Connected to Supabase PostgreSQL (${SupabaseConfig.activeUrl})'
                : 'Offline Prototype Mode (Local SQLite/Mock Store). Pass SUPABASE_URL to link live PostgreSQL.',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isConfigured ? const Color(0xFF10B981) : const Color(0xFF6A828B)),
          ),
          if (_healthData != null) ...[
            const SizedBox(height: 6),
            Text(
              'Database: ${_healthData!['database'] ?? "Checking"} • KeepAlive: Active (every 10m)',
              style: const TextStyle(fontSize: 10, color: Color(0xFF90ACB6), fontWeight: FontWeight.w600),
            ),
          ],
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Color(0xFF6A828B),
            letterSpacing: 1.1,
          ),
        ),
        const Spacer(),
        if (action != null)
          Text(
            action!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF234149),
            ),
          ),
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
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFD4E3EA)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF234149).withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
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
              color: const Color(0xFFE2EDF2),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD4E3EA))),
          child: Center(child: AppIcon(icon, color: const Color(0xFF234149), size: 19))));
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
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => destination)),
        child: BentoCard(
          variant: BentoCardVariant.elevatedWhite,
          borderRadius: 20,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF234149).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: AppIcon(icon, color: const Color(0xFF234149), size: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF16272E))),
                    const SizedBox(height: 2),
                    Text(detail, style: const TextStyle(fontSize: 11, color: Color(0xFF6A828B))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF90ACB6)),
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
