import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import '../util/secure_log.dart';

// ==============================================================================
// ADMIN SERVICE — thin wrappers over the SECURITY DEFINER admin_* RPCs.
// The database decides who may do what (admin_set_role, etc.); the UI only hides
// screens the user can't use.
// ==============================================================================

class AdminUser {
  final String id;
  final String? username;
  final String fullName;
  final String? email;
  final String? avatarUrl;
  final List<String> roles;

  const AdminUser({required this.id, this.username, required this.fullName, this.email, this.avatarUrl, this.roles = const []});

  factory AdminUser.fromJson(Map<String, dynamic> j) => AdminUser(
        id: j['id'] as String,
        username: j['username'] as String?,
        fullName: j['full_name'] as String? ?? '',
        email: j['email'] as String?,
        avatarUrl: j['avatar_url'] as String?,
        roles: ((j['roles'] as List?) ?? const []).map((e) => e.toString()).toList(),
      );
}

class LockedLogin {
  final String userId;
  final String username;
  final String fullName;
  final int strikes;
  final DateTime? lockedUntil; // null + permanent = until recovered
  final bool permanent;

  const LockedLogin({required this.userId, required this.username, required this.fullName, required this.strikes, this.lockedUntil, required this.permanent});

  factory LockedLogin.fromJson(Map<String, dynamic> j) => LockedLogin(
        userId: j['user_id'] as String,
        username: j['username'] as String? ?? '',
        fullName: j['full_name'] as String? ?? '',
        strikes: (j['strikes'] as num?)?.toInt() ?? 0,
        lockedUntil: DateTime.tryParse(j['locked_until'] as String? ?? '')?.toLocal(),
        permanent: j['permanent'] == true,
      );
}

/// Result of a recovery: the temporary password (shown once) or the reason it was refused.
class RecoverResult {
  final String? temporaryPassword;
  final String? error; // aal2_required | reason_required | forbidden | not_found | network
  const RecoverResult({this.temporaryPassword, this.error});
  bool get ok => temporaryPassword != null;
}

class ReportedUser {
  final String userId;
  final String username;
  final String fullName;
  final String restriction; // none | restricted | banned
  final int reports;
  final int reporters;
  final List<String> reasons;
  final String? sampleTitle;

  const ReportedUser({
    required this.userId,
    required this.username,
    required this.fullName,
    required this.restriction,
    required this.reports,
    required this.reporters,
    this.reasons = const [],
    this.sampleTitle,
  });

  factory ReportedUser.fromJson(Map<String, dynamic> j) => ReportedUser(
        userId: j['target_user'] as String,
        username: j['username'] as String? ?? '',
        fullName: j['full_name'] as String? ?? '',
        restriction: j['restriction'] as String? ?? 'none',
        reports: (j['reports'] as num?)?.toInt() ?? 0,
        reporters: (j['reporters'] as num?)?.toInt() ?? 0,
        reasons: ((j['reasons'] as List?) ?? const []).map((e) => e.toString()).toList(),
        sampleTitle: j['sample_title'] as String?,
      );
}

class BugReport {
  final String id;
  final String kind; // bug | crash | auth | network
  final String message;
  final String details;
  final String appVersion;
  final String os;
  final String status; // new | seen | fixed
  final DateTime createdAt;

  const BugReport({
    required this.id,
    required this.kind,
    required this.message,
    required this.details,
    required this.appVersion,
    required this.os,
    required this.status,
    required this.createdAt,
  });

  factory BugReport.fromJson(Map<String, dynamic> j) => BugReport(
        id: j['id'] as String,
        kind: j['kind'] as String? ?? 'bug',
        message: j['message'] as String? ?? '',
        details: j['details'] as String? ?? '',
        appVersion: j['app_version'] as String? ?? '',
        os: j['os'] as String? ?? '',
        status: j['status'] as String? ?? 'new',
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}

class FilterTerm {
  final String kind; // profanity | danger
  final String term;
  final String detail; // script (profanity) or severity (danger)
  const FilterTerm(this.kind, this.term, this.detail);
}

class AdminService {
  static SupabaseClient? get _c => SupabaseConfig.client;

  static Future<Map<String, dynamic>?> stats() async {
    try {
      final r = await _c?.rpc('admin_stats');
      return r == null ? null : Map<String, dynamic>.from(r as Map);
    } catch (e) {
      secureLog('[ADMIN] stats error: $e');
      return null;
    }
  }

  static Future<List<AdminUser>?> searchUsers(String query) async {
    try {
      final r = await _c?.rpc('admin_search_users', params: {'p_query': query.trim()});
      if (r == null) return null;
      return (r as List).map((e) => AdminUser.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      secureLog('[ADMIN] searchUsers error: $e');
      return null;
    }
  }

  /// Returns null on success, otherwise the database's error message (e.g. `superadmin_required`).
  static Future<String?> setRole(String userId, String role, {required bool grant}) async {
    try {
      await _c?.rpc('admin_set_role', params: {'p_user': userId, 'p_role': role, 'p_grant': grant});
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  static Future<List<LockedLogin>?> lockedLogins() async {
    try {
      final r = await _c?.rpc('admin_list_locked_logins');
      if (r == null) return null;
      return (r as List).map((e) => LockedLogin.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      secureLog('[ADMIN] lockedLogins error: $e');
      return null;
    }
  }

  /// Unlocks the account and returns a one-time temporary password. Needs a two-factor session.
  static Future<RecoverResult> recoverLogin(String userId, String reason) async {
    final client = _c;
    if (client == null) return const RecoverResult(error: 'network');
    try {
      final res = await client.functions.invoke('admin-recover-login', body: {'uid': userId, 'reason': reason});
      final pw = (res.data as Map?)?['temporary_password'] as String?;
      return pw == null ? const RecoverResult(error: 'forbidden') : RecoverResult(temporaryPassword: pw);
    } on FunctionException catch (e) {
      final code = (e.details is Map ? (e.details as Map)['error'] : null) as String?;
      return RecoverResult(error: code ?? 'forbidden');
    } catch (e) {
      secureLog('[ADMIN] recoverLogin error: $e');
      return const RecoverResult(error: 'network');
    }
  }

  static Future<List<ReportedUser>?> reportedUsers() async {
    try {
      final r = await _c?.rpc('admin_list_user_reports');
      if (r == null) return null;
      return (r as List).map((e) => ReportedUser.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      secureLog('[ADMIN] reportedUsers error: $e');
      return null;
    }
  }

  /// [action]: dismiss | warn | restrict | ban | reinstate. Returns null on success, else the database error code.
  static Future<String?> resolveUserReport(String userId, String action, {String? note}) async {
    try {
      await _c?.rpc('admin_resolve_user_report', params: {'p_user': userId, 'p_action': action, if (note != null) 'p_note': note});
      return null;
    } on PostgrestException catch (e) {
      final m = e.message;
      if (m.contains('reason_required')) return 'reason_required';
      if (m.contains('superadmin_required')) return 'superadmin_required';
      return 'failed';
    } catch (_) {
      return 'failed';
    }
  }

  static Future<List<BugReport>?> bugReports() async {
    try {
      final rows = await _c
          ?.from('client_errors')
          .select('id, kind, message, details, app_version, os, status, created_at')
          .order('created_at', ascending: false)
          .limit(100);
      if (rows == null) return null;
      return (rows as List).map((e) => BugReport.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      secureLog('[ADMIN] bugReports error: $e');
      return null;
    }
  }

  static Future<bool> setBugStatus(String id, String status) async {
    try {
      await _c?.from('client_errors').update({'status': status}).eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<List<FilterTerm>?> filterTerms() async {
    try {
      final r = await _c?.rpc('admin_filter_terms');
      if (r == null) return null;
      return (r as List)
          .map((e) => FilterTerm(e['kind'] as String, e['term'] as String, e['detail'] as String? ?? ''))
          .toList();
    } catch (e) {
      secureLog('[ADMIN] filterTerms error: $e');
      return null;
    }
  }

  static Future<bool> saveTerm(String kind, String term, String detail) async {
    try {
      await _c?.rpc('admin_save_filter_term', params: {'p_kind': kind, 'p_term': term, 'p_detail': detail});
      return true;
    } catch (e) {
      secureLog('[ADMIN] saveTerm error: $e');
      return false;
    }
  }

  static Future<bool> deleteTerm(String kind, String term) async {
    try {
      await _c?.rpc('admin_delete_filter_term', params: {'p_kind': kind, 'p_term': term});
      return true;
    } catch (e) {
      secureLog('[ADMIN] deleteTerm error: $e');
      return false;
    }
  }
}
