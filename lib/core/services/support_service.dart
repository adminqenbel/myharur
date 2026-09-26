import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../util/secure_log.dart';
import 'device_info.dart';
import 'supabase_config.dart';

// ==============================================================================
// SUPPORT: the AI fallback (edge function `support-ai`) and the prefilled e-mail to the team.
// Nothing here sends tokens, passwords or anything not listed in [buildSupportMailto].
// ==============================================================================

const supportEmails = ['adminqenbel@gmail.com', 'connectwithhemapriyan@gmail.com'];

enum AiStatus { ok, rateLimited, busy, unavailable, offline }

class AiAnswer {
  final AiStatus status;
  final String? text;
  const AiAnswer(this.status, [this.text]);
}

class SupportService {
  /// Asks the AI assistant. Only [message] (already typed by the person) and the language go to the server;
  /// the server removes e-mail addresses and long numbers before forwarding it to the model.
  static Future<AiAnswer> askAi(String message, {required String lang}) async {
    final client = SupabaseConfig.client;
    if (client == null) return const AiAnswer(AiStatus.unavailable);
    try {
      final res = await client.functions.invoke('support-ai', body: {'message': message, 'lang': lang});
      final text = (res.data as Map?)?['answer'] as String?;
      return text == null || text.isEmpty ? const AiAnswer(AiStatus.unavailable) : AiAnswer(AiStatus.ok, text);
    } on FunctionException catch (e) {
      final code = e.details is Map ? (e.details as Map)['error'] : null;
      secureLog('[SUPPORT] ai error ${e.status} $code');
      if (e.status == 429) return AiAnswer(code == 'busy' ? AiStatus.busy : AiStatus.rateLimited);
      return const AiAnswer(AiStatus.unavailable);
    } catch (e) {
      secureLog('[SUPPORT] ai failed: ${e.runtimeType}');
      return const AiAnswer(AiStatus.offline);
    }
  }

  /// A mailto: link to both support addresses, prefilled with what the team needs to help:
  /// username, member id, account e-mail, app version, phone OS/model, language and time. No tokens.
  static Future<String> buildSupportMailto({
    required UserProfile profile,
    required String accountEmail,
    required String language,
    required String intro,
    required String autoHeader,
    required String subject,
    DateTime? now,
  }) async {
    final when = (now ?? DateTime.now()).toIso8601String();
    final username = profile.username.startsWith('@') ? profile.username : '@${profile.username}';
    final body = [
      intro,
      '',
      '',
      '---------------------------',
      autoHeader,
      'Username: $username',
      'Member ID: ${profile.mmid}',
      'Account e-mail: $accountEmail',
      'App version: ${await DeviceInfo.appVersion()}',
      'Phone: ${await DeviceInfo.osDescription()}',
      'Language: $language',
      'Time: $when',
    ].join('\n');
    // encodeComponent uses %20 for spaces (mail apps show "+" literally)
    return 'mailto:${supportEmails.join(',')}?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';
  }
}
