import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api_client.dart';

class UpdateManager {
  static Future<void> checkUpdate(BuildContext context) async {
    try {
      final response = await ApiClient.dio.get('/config/');
      final minVersion = response.data['min_version'] as String;
      final latestVersion = response.data['latest_version'] as String;
      final updateUrl = response.data['update_url'] as String;
      
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final isForced = _isOlder(currentVersion, minVersion);
      final isOptional = !isForced && _isOlder(currentVersion, latestVersion);

      if (isForced || isOptional) {
        if (!context.mounted) return;
        _showUpdateDialog(context, updateUrl, isForced);
      }
    } catch (_) {
      // Fail silently if unable to check for updates
    }
  }

  static bool _isOlder(String local, String target) {
    try {
      final lParts = local.split('.').map(int.parse).toList();
      final tParts = target.split('.').map(int.parse).toList();
      for (int i = 0; i < 3; i++) {
        if (lParts[i] < tParts[i]) return true;
        if (lParts[i] > tParts[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static void _showUpdateDialog(BuildContext context, String url, bool isForced) {
    showDialog(
      context: context,
      barrierDismissible: !isForced,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => !isForced,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.system_update, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text('Update Available'),
            ],
          ),
          content: Text(
            isForced 
              ? 'A critical update is required to continue using MyHarur. Please download the latest version.'
              : 'A new version of MyHarur is available with new features and improvements. Would you like to update now?',
          ),
          actions: [
            if (!isForced)
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Later', style: TextStyle(color: Colors.grey)),
              ),
            ElevatedButton(
              onPressed: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text('Download Update'),
            ),
          ],
        ),
      ),
    );
  }
}
