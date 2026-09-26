import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../util/secure_log.dart';
import 'supabase_config.dart';

// ==============================================================================
// UPDATE POLICY. The database holds one public row (app_config): the newest build, the oldest build that
// still works, the store link and an optional message. The app compares its own build number to it:
//   build < min_supported_build -> blocking page      build < latest_build -> dismissible popup
// If the row cannot be read (offline, backend down) the app keeps working: an outage must never lock
// everybody out.
// ==============================================================================
enum UpdateLevel { none, available, required }

class UpdateInfo {
  final int latestBuild;
  final int minSupportedBuild;
  final String? url;
  final String? messageEn;
  final String? messageTa;
  const UpdateInfo({required this.latestBuild, required this.minSupportedBuild, this.url, this.messageEn, this.messageTa});

  factory UpdateInfo.fromJson(Map<String, dynamic> j) => UpdateInfo(
        latestBuild: (j['latest_build'] as num?)?.toInt() ?? 0,
        minSupportedBuild: (j['min_supported_build'] as num?)?.toInt() ?? 0,
        url: j['update_url'] as String?,
        messageEn: j['message_en'] as String?,
        messageTa: j['message_ta'] as String?,
      );

  UpdateLevel levelFor(int build) {
    if (build < minSupportedBuild) return UpdateLevel.required;
    if (build < latestBuild) return UpdateLevel.available;
    return UpdateLevel.none;
  }

  String? message(String languageCode) {
    final m = languageCode == 'ta' ? messageTa : messageEn;
    return (m == null || m.trim().isEmpty) ? null : m.trim();
  }
}

class UpdateService {
  static final ValueNotifier<UpdateLevel> level = ValueNotifier(UpdateLevel.none);
  static UpdateInfo? info;
  static DateTime? _lastCheck;
  static const _minGap = Duration(hours: 1);

  /// Reads the policy and updates [level]. Cheap: one row, at most once an hour unless [force].
  static Future<void> check({bool force = false}) async {
    final client = SupabaseConfig.client;
    if (client == null) return;
    final last = _lastCheck;
    if (!force && last != null && DateTime.now().difference(last) < _minGap) return;
    _lastCheck = DateTime.now();
    try {
      final row = await client.from('app_config').select().eq('id', 1).maybeSingle();
      if (row == null) return;
      final build = int.tryParse((await PackageInfo.fromPlatform()).buildNumber) ?? 0;
      info = UpdateInfo.fromJson(row);
      level.value = info!.levelFor(build);
    } catch (e) {
      secureLog('[UPDATE] check skipped: $e'); // fail open
    }
  }

  @visibleForTesting
  static void debugSet(UpdateLevel l, UpdateInfo? i) {
    info = i;
    level.value = l;
  }
}
