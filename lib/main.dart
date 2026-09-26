import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/l10n/locale_controller.dart';
import 'core/models/weather.dart';
import 'core/services/alerts_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/error_reporter.dart';
import 'core/services/feature_flag_service.dart';
import 'core/services/push_service.dart';
import 'core/services/supabase_config.dart';
import 'core/services/weather_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/ui.dart';
import 'features/account/account_page.dart';
import 'features/account/notifications_page.dart';
import 'features/auth/auth_page.dart';
import 'features/errors/error_pages.dart';
import 'features/home/home_page.dart';
import 'features/moderation/moderation_page.dart';
import 'features/news/news_page.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/reports/reports_page.dart';
import 'features/security/force_password_page.dart';
import 'features/security/mfa_pages.dart';
import 'features/security/suspended_page.dart';
import 'features/splash/splash_gate.dart';
import 'features/update/update_gate.dart';
import 'features/weather/weather_page.dart';

// ==============================================================================
// MAIN ENTRY POINT
// Every uncaught error is caught here: a widget that fails to build shows a small friendly box,
// uncaught async errors are reported (redacted) instead of crashing, and a crash loop shows the
// crash page with Restart / Report.
// ==============================================================================
Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    _installErrorHandlers();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    await Future.wait([LocaleController.instance.load(), warmBrandLogo()]);
    await SupabaseConfig.initialize();
    AuthService.init();
    unawaited(FeatureFlagService.loadFlags()); // fail-safe defaults; don't delay first paint
    unawaited(WeatherService.fetch(WeatherLocation.harur)); // warm the cache during the splash

    runApp(const AppRoot());
  }, (error, stack) => AppErrors.handle(error, stack));
}

void _installErrorHandlers() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppErrors.handle(details.exception, details.stack, screen: details.library ?? '');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppErrors.handle(error, stack);
    return true; // handled: do not crash the process
  };
  // In release a broken widget shows a small neutral box instead of Flutter's red error screen.
  ErrorWidget.builder = (details) => kDebugMode ? ErrorWidget(details) : const FriendlyErrorBox();
}

// ==============================================================================
// ROOT: "Restart" rebuilds everything under a fresh key.
// ==============================================================================
class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppErrors.restartCount,
      builder: (context, n, _) => KeyedSubtree(key: ValueKey(n), child: const MyHarurApp()),
    );
  }
}

class MyHarurApp extends StatelessWidget {
  const MyHarurApp({super.key});

  /// Routes that belong to the OAuth return trip must not be treated as "not found".
  static bool _isSignInReturn(String? name) {
    final n = name ?? '';
    return n.isEmpty || n == '/' || n.contains('login-callback') || n.contains('code=') || n.contains('access_token') || n.contains('error=');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) => MaterialApp(
        onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        scrollBehavior: const BouncingScrollBehavior(),
        locale: LocaleController.instance.locale,
        supportedLocales: LocaleController.supported,
        localizationsDelegates: AppLocalizations.localizationsDelegates,

        // The crash page sits above everything (including dialogs and other routes).
        builder: (context, child) => ValueListenableBuilder<CrashInfo?>(
          valueListenable: AppErrors.crash,
          builder: (context, info, _) => info == null ? (child ?? const SizedBox.shrink()) : CrashPage(info: info),
        ),

        home: const SplashGate(child: UpdateGate(child: _AuthShell())),
        onGenerateRoute: (settings) => MaterialPageRoute(
          settings: settings,
          builder: (_) => _isSignInReturn(settings.name) ? const _AuthShell() : const NotFoundPage(),
        ),
      ),
    );
  }
}

// ==============================================================================
// AUTH SHELL: sign-in, sign-in failure, onboarding, two-factor gates, then the app
// ==============================================================================
class _AuthShell extends StatelessWidget {
  const _AuthShell();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AuthNotifier.instance, AuthService.failure, AuthService.mfa]),
      builder: (context, _) {
        final failure = AuthService.failure.value;
        if (!AuthService.isAuthenticated) {
          if (failure != null) {
            return AuthFailurePage(
              reason: failure,
              onUseUsername: () {
                AuthService.clearFailure();
                AuthPage.showUsernameIntent.value++;
              },
            );
          }
          return const AuthPage();
        }
        if (!AuthService.currentProfile.isActive && !AuthService.currentProfile.isGuest) return const SuspendedPage();
        if (AuthService.currentProfile.mustChangePassword) return const ForcePasswordPage();
        if (!AuthService.currentProfile.isOnboardingComplete) return const OnboardingPage();

        // Two-factor: admins must have it; anyone who has enrolled must pass the code check.
        final mfa = AuthService.mfa.value;
        if (mfa == MfaStatus.needsChallenge) return const MfaChallengePage();
        if (mfa == MfaStatus.notEnrolled && AuthService.currentProfile.requiresMfa) return const MfaEnrollPage(mandatory: true);

        return const TownShell();
      },
    );
  }
}

// ==============================================================================
// TOWN SHELL: Home | News | Weather | Reports | (Review, staff only) | Account
// Pages are built lazily on first visit and then kept alive (scroll positions survive).
// ==============================================================================
enum AppTab { home, news, weather, reports, review, account }

class TownShell extends StatefulWidget {
  const TownShell({super.key});

  /// Lets a page (e.g. a "See all" link on Home) switch tabs.
  static void goTo(BuildContext context, AppTab tab) => context.findAncestorStateOfType<_TownShellState>()?._select(tab);

  @override
  State<TownShell> createState() => _TownShellState();
}

class _TownShellState extends State<TownShell> {
  AppTab _tab = AppTab.home;
  final Set<AppTab> _visited = {AppTab.home};
  int _pending = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refreshPending();
    _timer = Timer.periodic(const Duration(seconds: 90), (_) => _refreshPending());
    PushService.openReportsRequests.addListener(_openReports);
    // ask once, a few seconds in, so it never competes with the first screen
    Future<void>.delayed(const Duration(seconds: 6), () {
      if (mounted) maybeAskAboutNotifications(context);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    PushService.openReportsRequests.removeListener(_openReports);
    super.dispose();
  }

  /// A tapped notification lands on the Reports tab.
  void _openReports() => _select(AppTab.reports);

  Future<void> _refreshPending() async {
    if (!AuthService.currentProfile.isStaff) {
      if (_pending != 0 && mounted) setState(() => _pending = 0);
      return;
    }
    final n = await AlertsService.pendingCount();
    if (mounted && n != _pending) setState(() => _pending = n);
  }

  void _select(AppTab tab) {
    if (tab == _tab) return;
    setState(() {
      _tab = tab;
      _visited.add(tab);
    });
    if (tab == AppTab.review) _refreshPending();
  }

  Widget _page(AppTab tab) => switch (tab) {
        AppTab.home => const HomePage(),
        AppTab.news => const NewsPage(),
        AppTab.weather => const WeatherPage(),
        AppTab.reports => const ReportsPage(),
        AppTab.review => const ModerationPage(asTab: true),
        AppTab.account => const AccountPage(),
      };

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return ListenableBuilder(
      listenable: AuthNotifier.instance, // roles can change while the app is open
      builder: (context, _) {
        final staff = AuthService.currentProfile.isStaff;
        final tabs = <AppTab>[AppTab.home, AppTab.news, AppTab.weather, AppTab.reports, if (staff) AppTab.review, AppTab.account];
        final current = tabs.contains(_tab) ? _tab : AppTab.home;

        TabSpec spec(AppTab tab) => switch (tab) {
              AppTab.home => TabSpec(t.tabHome, Icons.home_outlined, Icons.home_rounded),
              AppTab.news => TabSpec(t.tabNews, Icons.newspaper_outlined, Icons.newspaper_rounded),
              AppTab.weather => TabSpec(t.tabWeather, Icons.cloud_outlined, Icons.cloud_rounded),
              AppTab.reports => TabSpec(t.tabReports, Icons.campaign_outlined, Icons.campaign_rounded),
              AppTab.review => TabSpec(t.tabReview, Icons.fact_check_outlined, Icons.fact_check_rounded, badge: _pending),
              AppTab.account => TabSpec(t.tabAccount, Icons.person_outline_rounded, Icons.person_rounded),
            };

        return Scaffold(
          backgroundColor: AppColors.background,
          body: FadeOnChange(
            token: current,
            child: IndexedStack(
              index: tabs.indexOf(current),
              children: [for (final tab in tabs) _visited.contains(tab) ? _page(tab) : const SizedBox.shrink()],
            ),
          ),
          bottomNavigationBar: AppTabBar(
            selected: tabs.indexOf(current),
            tabs: [for (final tab in tabs) spec(tab)],
            onTap: (i) => _select(tabs[i]),
          ),
        );
      },
    );
  }
}
