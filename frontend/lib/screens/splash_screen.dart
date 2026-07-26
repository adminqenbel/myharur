import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../api_client.dart';
import '../providers/auth_provider.dart';
import 'update_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    // 1. Check version
    try {
      final response = await ApiClient.dio.get('/config/');
      final minVersion = response.data['min_version'] as String;
      final updateUrl = response.data['update_url'] as String;
      final packageInfo = await PackageInfo.fromPlatform();
      if (_isUpdateRequired(packageInfo.version, minVersion)) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => UpdateScreen(updateUrl: updateUrl)),
          );
          return;
        }
      }
    } catch (_) {}

    // 2. Try auto-login
    await ref.read(authProvider.notifier).tryAutoLogin();
    final auth = ref.read(authProvider);

    if (!mounted) return;

    if (!auth.isLoggedIn) {
      context.go('/login');
    } else if (!auth.isSetupComplete) {
      context.go('/onboarding');
    } else {
      context.go('/home');
    }
  }

  bool _isUpdateRequired(String local, String minimum) {
    try {
      final lParts = local.split('.').map(int.parse).toList();
      final mParts = minimum.split('.').map(int.parse).toList();
      for (int i = 0; i < 3; i++) {
        if (lParts[i] < mParts[i]) return true;
        if (lParts[i] > mParts[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', height: 100),
            const SizedBox(height: 24),
            const CircularProgressIndicator(strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
