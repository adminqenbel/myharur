import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/home/presentation/main_layout.dart';
import '../../features/home/presentation/map_widget.dart';
import '../../features/news/presentation/news_screen.dart';
import '../../features/shops/presentation/shops_screen.dart';
import '../../features/emergency/presentation/emergency_screen.dart';
import '../../features/emergency/presentation/custom_emergency_screen.dart';
import '../../features/admin/presentation/admin_dashboard.dart';

// Placeholders for other screens
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    // In a real app, this would check auth state and then route
    Future.delayed(const Duration(seconds: 2), () {
      context.go('/login');
    });
    return Scaffold(body: Center(child: Image.asset('assets/logo.png', height: 150)));
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Home Dashboard")), 
    body: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Harur Town Map (10km Radius)'),
        ),
        const Expanded(child: HarurMapWidget()),
      ],
    )
  );
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Profile")), 
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("User Profile"),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.push('/admin'),
            child: const Text('Admin Dashboard'),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => context.go('/login'),
            child: const Text('Logout'),
          ),
        ],
      ),
    ),
  );
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/shops',
            builder: (context, state) => const ShopsScreen(),
          ),
          GoRoute(
            path: '/news',
            builder: (context, state) => const NewsScreen(),
          ),
          GoRoute(
            path: '/emergency',
            builder: (context, state) => const EmergencyScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/custom_emergency',
        builder: (context, state) => const CustomEmergencyScreen(),
      ),
    ],
  );
});
