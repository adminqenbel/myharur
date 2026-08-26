import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/services/supabase_config.dart';
import 'core/services/auth_service.dart';
import 'core/services/feature_flag_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/glass_components.dart';
import 'features/auth/auth_page.dart';
import 'features/home/home_page.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/account/account_page.dart';
import 'features/explore/explore_page.dart';
import 'features/alerts/submit_alert_page.dart';

// ==============================================================================
// MAIN ENTRY POINT
// ==============================================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialize Supabase (MyHarur product DB)
  await SupabaseConfig.initialize();

  // Wire up auth state listener
  AuthService.init();

  // Load feature flags from DB (fail-safe — defaults all off)
  await FeatureFlagService.loadFlags();

  runApp(const MyHarurApp());
}

// ==============================================================================
// ROOT APP
// ==============================================================================
class MyHarurApp extends StatelessWidget {
  const MyHarurApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyHarur',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,

      // Deep-link handler for Google OAuth callback
      onGenerateRoute: (settings) {
        if (settings.name != null &&
            settings.name!.startsWith('/login-callback')) {
          return MaterialPageRoute(builder: (_) => const _AuthShell());
        }
        return MaterialPageRoute(builder: (_) => const _AuthShell());
      },

      home: const _AuthShell(),
    );
  }
}

// ==============================================================================
// AUTH SHELL — Listens to AuthNotifier, routes to the correct screen
// ==============================================================================
class _AuthShell extends StatelessWidget {
  const _AuthShell();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthNotifier.instance,
      builder: (context, _) {
        final authenticated = AuthService.isAuthenticated;
        final profile = AuthService.currentProfile;

        // Not logged in → Auth page
        if (!authenticated) {
          return const AuthPage();
        }

        // Logged in but onboarding not complete → Onboarding flow
        if (!profile.isOnboardingComplete) {
          return const OnboardingPage();
        }

        // Fully authenticated and onboarded → Main shell
        return const TownShell();
      },
    );
  }
}

// ==============================================================================
// TOWN SHELL — Main app scaffold with bottom navigation
// Modules gated by feature flags (jobs/events/chat/tournaments are all OFF v1)
// ==============================================================================
class TownShell extends StatefulWidget {
  const TownShell({super.key});

  @override
  State<TownShell> createState() => _TownShellState();
}

class _TownShellState extends State<TownShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    _AllAlertsPage(),
    ExplorePage(),
    AccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.systemBackground,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      extendBody: true,
      bottomNavigationBar: PillNavBar(
        selectedIndex: _selectedIndex,
        items: buildNavItems(),
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

// ==============================================================================
// All Alerts Tab — Full unfiltered alerts list + submit CTA
// ==============================================================================
class _AllAlertsPage extends StatelessWidget {
  const _AllAlertsPage();

  @override
  Widget build(BuildContext context) {
    return AtmosphericBackground(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('All Alerts', style: AppTextStyles.largeTitle),
                      Text(
                        'Road · Electricity · Water · Government',
                        style: AppTextStyles.footnote,
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SubmitAlertPage()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text('Report',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Reuse HomePage widget but in expanded context — this gives the 
            // full feed with all categories without nesting issue
            const Expanded(child: HomePage()),
          ],
        ),
      ),
    );
  }
}
