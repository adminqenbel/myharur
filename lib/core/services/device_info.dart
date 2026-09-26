import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// What we attach to a bug report and to support e-mails: app version and the phone's OS/model.
/// Nothing that identifies the person (no advertising id, serial, IMEI, account or token).
class DeviceInfo {
  static Future<String> appVersion() async {
    try {
      final i = await PackageInfo.fromPlatform();
      return '${i.version}+${i.buildNumber}';
    } catch (_) {
      return 'unknown';
    }
  }

  static Future<String> osDescription() async {
    if (kIsWeb) return 'web';
    try {
      final plugin = DeviceInfoPlugin();
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final a = await plugin.androidInfo;
          return 'Android ${a.version.release} (${a.model})';
        case TargetPlatform.iOS:
          final i = await plugin.iosInfo;
          return 'iOS ${i.systemVersion} (${i.utsname.machine})';
        default:
          return defaultTargetPlatform.name;
      }
    } catch (_) {
      return defaultTargetPlatform.name;
    }
  }
}
