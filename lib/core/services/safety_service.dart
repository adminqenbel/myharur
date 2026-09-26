import 'package:supabase_flutter/supabase_flutter.dart';
import '../util/secure_log.dart';
import 'supabase_config.dart';

// ==============================================================================
// SAFETY: report a post, block its author, report a bug. All go through the database's
// SECURITY DEFINER functions, which enforce rate limits and never reveal who wrote a post.
// ==============================================================================

const reportReasons = ['spam', 'false', 'abuse', 'harassment', 'inappropriate', 'other'];

enum SafetyResult { ok, rateLimited, invalid, failed }

class BlockedAuthor {
  final String userId;
  final String label; // the title of the post that was blocked, never the person's name
  const BlockedAuthor(this.userId, this.label);
}

class SafetyService {
  static SupabaseClient? get _c => SupabaseConfig.client;

  static Future<SafetyResult> reportContent(String alertId, String reason, {String? note}) async {
    final client = _c;
    if (client == null) return SafetyResult.failed;
    try {
      await client.rpc('report_content', params: {'p_alert_id': alertId, 'p_reason': reason, if (note != null && note.trim().isNotEmpty) 'p_note': note.trim()});
      return SafetyResult.ok;
    } on PostgrestException catch (e) {
      secureLog('[SAFETY] report error: ${e.message}');
      if (e.message.contains('rate_limited')) return SafetyResult.rateLimited;
      if (e.message.contains('invalid')) return SafetyResult.invalid;
      return SafetyResult.failed;
    } catch (_) {
      return SafetyResult.failed;
    }
  }

  static Future<SafetyResult> blockAuthor(String alertId) async {
    final client = _c;
    if (client == null) return SafetyResult.failed;
    try {
      await client.rpc('block_author', params: {'p_alert_id': alertId});
      return SafetyResult.ok;
    } on PostgrestException catch (e) {
      secureLog('[SAFETY] block error: ${e.message}');
      return e.message.contains('invalid_target') ? SafetyResult.invalid : SafetyResult.failed;
    } catch (_) {
      return SafetyResult.failed;
    }
  }

  static Future<List<BlockedAuthor>?> myBlocks() async {
    final client = _c;
    if (client == null) return null;
    try {
      final rows = await client.from('user_blocks').select('blocked, label').order('created_at', ascending: false);
      return (rows as List).map((r) => BlockedAuthor(r['blocked'] as String, r['label'] as String? ?? '')).toList();
    } catch (e) {
      secureLog('[SAFETY] blocks error: $e');
      return null;
    }
  }

  static Future<bool> unblock(String userId) async {
    try {
      await _c?.rpc('unblock_user', params: {'p_user': userId});
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<SafetyResult> reportBug(String title, String details, {required String appVersion, required String os}) async {
    final client = _c;
    if (client == null) return SafetyResult.failed;
    try {
      await client.rpc('report_bug', params: {'p_title': title.trim(), 'p_details': details.trim(), 'p_app_version': appVersion, 'p_os': os});
      return SafetyResult.ok;
    } on PostgrestException catch (e) {
      secureLog('[SAFETY] bug error: ${e.message}');
      if (e.message.contains('rate_limited')) return SafetyResult.rateLimited;
      if (e.message.contains('invalid_length')) return SafetyResult.invalid;
      return SafetyResult.failed;
    } catch (_) {
      return SafetyResult.failed;
    }
  }
}
