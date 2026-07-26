import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../api_client.dart';
import 'update_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkVersionAndRoute();
  }

  Future<void> _checkVersionAndRoute() async {
    try {
      // 1. Fetch config from server
      final response = await ApiClient.dio.get('/config/');
      final minVersion = response.data['min_version'] as String;
      final updateUrl = response.data['update_url'] as String;

      // 2. Get local app version
      final packageInfo = await PackageInfo.fromPlatform();
      final localVersion = packageInfo.version;

      // 3. Compare versions
      if (_isUpdateRequired(localVersion, minVersion)) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => UpdateScreen(updateUrl: updateUrl),
            ),
          );
        }
        return;
      }
    } catch (e) {
      // If config fails, just proceed for now
      debugPrint("Config fetch error: $e");
    }

    // 4. If no update required, go to login
    if (mounted) {
      context.go('/login');
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
      return false; // Equal
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
