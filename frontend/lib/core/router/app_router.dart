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
import '../network/api_client.dart';

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
          child: Text('MyHarur Map (10km Radius)'),
        ),
        const Expanded(child: MyHarurMapWidget()),
      ],
    )
  );
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfile();
  }

  Future<Map<String, dynamic>> _fetchProfile() async {
    // If not logged in (e.g. Guest mode), ApiClient headers won't have Authorization.
    // In that case, this will throw 401, which we catch.
    final response = await ApiClient.dio.get('/users/me');
    return response.data;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("My Profile")), 
    body: FutureBuilder<Map<String, dynamic>>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final user = snapshot.data;
        
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (user != null && user['profile'] != null && user['profile']['avatar_url'] != null)
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(user['profile']['avatar_url']),
                )
              else
                const CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person, size: 50),
                ),
              const SizedBox(height: 20),
              if (user != null) ...[
                Text(
                  '${user['profile']?['first_name'] ?? ''} ${user['profile']?['last_name'] ?? ''}'.trim(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(user['email'] ?? '', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user['role']?['name'] ?? 'User',
                    style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ] else ...[
                const Text("Guest User", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const Text("Please log in to view your profile.", style: TextStyle(color: Colors.grey)),
              ],
              const SizedBox(height: 40),
              if (user != null && user['role'] != null && user['role']['name'] != 'User')
                ElevatedButton(
                  onPressed: () => context.push('/admin'),
                  child: const Text('Admin Dashboard'),
                ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () {
                  ApiClient.dio.options.headers.remove('Authorization');
                  context.go('/login');
                },
                child: Text(user != null ? 'Logout' : 'Log In'),
              ),
            ],
          ),
        );
      }
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
