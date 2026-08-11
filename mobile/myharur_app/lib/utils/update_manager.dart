import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api_client.dart';
import '../theme.dart';
import '../widgets/design_system.dart';

class UpdateManager {
  static bool _dialogShowing = false;

  static Future<void> checkUpdate(BuildContext context) async {
    if (_dialogShowing) return;
    try {
      final response = await ApiClient.dio.get('/config/');
      final data = response.data;
      final minVersion = (data['min_version'] ?? '1.0.0').toString();
      final latestVersion = (data['latest_version'] ?? '1.0.0').toString();
      final apkUrl = (data['apk_url'] ?? data['update_url'] ?? 'https://myharur.onrender.com/static/myharur.apk').toString();
      final releaseNotes = (data['release_notes'] ?? 'General performance and stability improvements.').toString();
      final forceUpdateFlag = data['force_update'] as bool? ?? false;
      final isMaintenance = data['maintenance_mode'] as bool? ?? false;

      if (isMaintenance) {
        if (!context.mounted) return;
        _showMaintenanceDialog(context);
        return;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version.isEmpty ? '1.0.0' : packageInfo.version;

      final isOlderThanMin = _isOlder(currentVersion, minVersion);
      final isOlderThanLatest = _isOlder(currentVersion, latestVersion);
      final isForced = isOlderThanMin || forceUpdateFlag;

      if (isForced || isOlderThanLatest) {
        if (!context.mounted) return;
        _dialogShowing = true;
        _showAppleUpdateDialog(
          context: context,
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          apkUrl: apkUrl,
          releaseNotes: releaseNotes,
          isForced: isForced,
        );
      }
    } catch (_) {
      // Ignore update check failures gracefully
    }
  }

  static bool _isOlder(String local, String target) {
    try {
      final lParts = local.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final tParts = target.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      
      while (lParts.length < 3) lParts.add(0);
      while (tParts.length < 3) tParts.add(0);

      for (int i = 0; i < 3; i++) {
        if (lParts[i] < tParts[i]) return true;
        if (lParts[i] > tParts[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static void _showAppleUpdateDialog({
    required BuildContext context,
    required String currentVersion,
    required String latestVersion,
    required String apkUrl,
    required String releaseNotes,
    required bool isForced,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isDismissible: !isForced,
      enableDrag: !isForced,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PopScope(
        canPop: !isForced,
        onPopInvoked: (_) {
          if (!isForced) _dialogShowing = false;
        },
        child: MHBottomSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.appleBlue.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.system_update_rounded, size: 40, color: AppTheme.appleBlue),
              ),
              const SizedBox(height: 16),
              Text(
                'New Update Available',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MHBadge(text: 'Current v$currentVersion', color: Colors.grey),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.appleBlue),
                  const SizedBox(width: 8),
                  MHBadge(text: 'Latest v$latestVersion', color: AppTheme.appleBlue),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.stars_rounded, size: 18, color: AppTheme.appleBlue),
                        const SizedBox(width: 6),
                        Text('What\'s New in v$latestVersion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.appleBlue)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      releaseNotes,
                      style: TextStyle(fontSize: 13, height: 1.4, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              MHButton(
                text: 'Download & Install Update',
                icon: Icons.download_rounded,
                onPressed: () async {
                  final uri = Uri.parse(apkUrl);
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (_) {
                    try {
                      await launchUrl(uri);
                    } catch (_) {}
                  }
                },
              ),
              if (!isForced) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    _dialogShowing = false;
                    Navigator.pop(ctx);
                  },
                  child: Text('Skip for Now', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.w600)),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  static void _showMaintenanceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PopScope(
        canPop: false,
        child: MHBottomSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.build_rounded, size: 40, color: Colors.orange),
              ),
              const SizedBox(height: 16),
              Text(
                'System Maintenance',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 12),
              Text(
                'MyHarur is currently undergoing scheduled platform upgrades. All services will resume shortly.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.4, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
