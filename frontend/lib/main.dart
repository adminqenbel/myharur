import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'theme.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/update_screen.dart';
import 'screens/main_layout.dart';
import 'screens/home_screen.dart';
import 'screens/community_screen.dart';
import 'screens/emergency_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/market_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/set_password_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/username_setup_screen.dart';
import 'providers/auth_provider.dart';

import 'services/notification_service.dart';

import 'utils/image_upload_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiClient.init();
  LocalImageServer.start();
  final notificationService = NotificationService();
  await notificationService.init();
  notificationService.startSimulatedUpdates();
  runApp(const ProviderScope(child: MyHarurApp()));
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  redirect: (context, state) {
    final container = ProviderScope.containerOf(context, listen: false);
    final auth = container.read(authProvider);
    final loc = state.matchedLocation;

    if (loc == '/splash' || loc == '/login') return null;
    if (!auth.isLoggedIn) return '/login';
    if (auth.usernameRequired && loc != '/username-setup') return '/username-setup';
    if (!auth.usernameRequired && !auth.isSetupComplete && loc != '/onboarding' && loc != '/username-setup') return '/onboarding';
    if (!auth.usernameRequired && auth.isSetupComplete && (loc == '/username-setup' || loc == '/onboarding')) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
    GoRoute(path: '/update', builder: (context, state) => UpdateScreen(updateUrl: (state.extra as String?) ?? 'https://myharur.onrender.com')),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    GoRoute(path: '/edit-profile', builder: (context, state) => const EditProfileScreen()),
    GoRoute(path: '/change-password', builder: (context, state) => const ChangePasswordScreen()),
    GoRoute(path: '/set-password', builder: (context, state) => const SetPasswordScreen()),
    GoRoute(path: '/admin', builder: (context, state) => const AdminDashboardScreen()),
    GoRoute(path: '/username-setup', builder: (context, state) => const UsernameSetupScreen()),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(path: '/market', builder: (context, state) => const MarketScreen()),
        GoRoute(path: '/community', builder: (context, state) => const CommunityScreen()),
        GoRoute(path: '/report', builder: (context, state) => const EmergencyScreen()),
        GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      ],
    ),
  ],
);

class MyHarurApp extends ConsumerWidget {
  const MyHarurApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'MyHarur',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
