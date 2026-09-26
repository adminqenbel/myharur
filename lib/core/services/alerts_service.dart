import "package:supabase_flutter/supabase_flutter.dart";
import "supabase_config.dart";
import "../models/alert.dart";
import "../models/place.dart";
import '../util/secure_log.dart';

// ==============================================================================
// ALERTS SERVICE — v1 core launch surface
//
// Lifecycle (enforced in Postgres, see supabase/migrations/*moderation_pipeline*):
//   submit  -> automated filter -> 'pending' (or auto 'rejected')
//   review  -> any moderator/admin approves or rejects via moderate_alert()
//   feed    -> only 'published', unexpired alerts are public
// The client never chooses status, source or author; the database overwrites them.
// ==============================================================================

enum SubmitOutcome {
  submitted,     // accepted, awaiting human review
  autoRejected,  // blocked by the automated filter
  rateLimited,   // too many recent submissions
  cooldown,      // 3 auto-rejections in 24 h: posting paused
  restricted,    // the account is restricted pending staff review
  invalidImage,  // a photo was refused
  invalid,       // failed length validation
  accountIssue,  // profile missing / account disabled / signed out
  failed,        // network or unexpected error
}

const _selectFields = """
  id, kind, category, title, body, source, status, link_url, image_paths,
  published_as_role, created_by_uid, expires_at,
  emergency_tagged, created_at,
  location_text, location_lat, location_lng, location_source,
  moderation_flags, flagged_by_system, moderation_reason
""";

class AlertsService {
  /// Public feed: published, unexpired alerts only.
  /// Returns null on error (so the UI can show a retry state) and [] when empty.
  static Future<List<Alert>?> fetchFeedAlerts({
    String? category,
    String kind = "report",
    int limit = 30,
  }) async {
    final client = SupabaseConfig.client;
    if (client == null) return null;

    try {
      var query = client
          .from("alerts")
          .select(_selectFields)
          .eq("status", "published")
          .eq("kind", kind)
          .or("expires_at.is.null,expires_at.gt.${DateTime.now().toUtc().toIso8601String()}");

      if (category != null) query = query.eq("category", category);

      final response = await query
          .order("emergency_tagged", ascending: false)
          .order("created_at", ascending: false)
          .limit(limit);

      return _parse(response);
    } catch (e) {
      secureLog("[ALERTS] fetchFeedAlerts error: $e");
      return null;
    }
  }

  /// Submit an alert (residents and staff alike). Goes through the automated
  /// filter, then waits for a moderator/admin.
  static Future<SubmitOutcome> submitAlert({
    required String category,
    required String title,
    required String body,
    String kind = "report",
    String? linkUrl,
    List<String> imagePaths = const [],
    PickedLocation? location,
    bool emergencyTagged = false,
  }) async {
    final client = SupabaseConfig.client;
    if (client == null || client.auth.currentUser == null) {
      return SubmitOutcome.accountIssue;
    }

    try {
      final row = await client
          .from("alerts")
          .insert({
            "kind": kind,
            "category": category,
            if (linkUrl != null && linkUrl.trim().isNotEmpty) "link_url": linkUrl.trim(),
            if (imagePaths.isNotEmpty) "image_paths": imagePaths,
            "title": title.trim(),
            "body": body.trim(),
            if (location != null && !location.isEmpty) ...location.toColumns("location"),
            "emergency_tagged": emergencyTagged,
          })
          .select("status")
          .single();
      return row["status"] == "rejected"
          ? SubmitOutcome.autoRejected
          : SubmitOutcome.submitted;
    } on PostgrestException catch (e) {
      secureLog("[ALERTS] submitAlert error: ${e.message}");
      final m = e.message;
      if (m.contains("rate_limited")) return SubmitOutcome.rateLimited;
      if (m.contains("cooldown")) return SubmitOutcome.cooldown;
      if (m.contains("account_restricted")) return SubmitOutcome.restricted;
      if (m.contains("invalid_image")) return SubmitOutcome.invalidImage;
      if (m.contains("invalid_length")) return SubmitOutcome.invalid;
      if (m.contains("profile_missing") ||
          m.contains("account_disabled") ||
          m.contains("authentication_required")) {
        return SubmitOutcome.accountIssue;
      }
      return SubmitOutcome.failed;
    } catch (e) {
      secureLog("[ALERTS] submitAlert error: $e");
      return SubmitOutcome.failed;
    }
  }

  /// The signed-in person's own posts (both kinds, any status). Deleted posts are not returned.
  static Future<List<Alert>?> fetchMine({int limit = 50}) async {
    final client = SupabaseConfig.client;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) return null;
    try {
      final response = await client
          .from("alerts")
          .select(_selectFields)
          .eq("created_by_uid", uid)
          .order("created_at", ascending: false)
          .limit(limit);
      return _parse(response);
    } catch (e) {
      secureLog("[ALERTS] fetchMine error: $e");
      return null;
    }
  }

  /// Deletes a post: the author any time, staff with a written [reason].
  /// Returns null on success, otherwise the database error code (`forbidden`, `reason_required`, `network`).
  static Future<String?> deleteContent(String id, {String? reason}) async {
    final client = SupabaseConfig.client;
    if (client == null) return "network";
    try {
      await client.rpc("delete_content", params: {"p_id": id, if (reason != null) "p_reason": reason});
      return null;
    } on PostgrestException catch (e) {
      secureLog("[ALERTS] delete error: ${e.message}");
      final m = e.message;
      if (m.contains("reason_required")) return "reason_required";
      if (m.contains("forbidden")) return "forbidden";
      if (m.contains("not_found")) return "not_found";
      return "failed";
    } catch (e) {
      secureLog("[ALERTS] delete error: $e");
      return "network";
    }
  }

  // ── Staff: review queue ─────────────────────────────────────────────────────

  /// Pending alerts for review. Emergency first, then system-flagged, then oldest.
  /// RLS returns rows only to moderators/admins; anyone else gets just their own.
  static Future<List<Alert>?> fetchReviewQueue({int limit = 50}) async {
    final client = SupabaseConfig.client;
    if (client == null) return null;
    try {
      final response = await client
          .from("alerts")
          .select(_selectFields)
          .eq("status", "pending")
          .order("emergency_tagged", ascending: false)
          .order("flagged_by_system", ascending: false)
          .order("created_at", ascending: true)
          .limit(limit);
      return _parse(response);
    } catch (e) {
      secureLog("[ALERTS] fetchReviewQueue error: $e");
      return null;
    }
  }

  /// Number of alerts waiting for review (staff only; RLS returns 0 for everyone else).
  static Future<int> pendingCount() async {
    final client = SupabaseConfig.client;
    if (client == null) return 0;
    try {
      final res = await client.from("alerts").select("id").eq("status", "pending").count(CountOption.exact);
      return res.count;
    } catch (e) {
      secureLog("[ALERTS] pendingCount error: $e");
      return 0;
    }
  }

  /// Approve an alert (goes live for [liveHours]).
  static Future<bool> approve(String alertId, {int liveHours = 168}) =>
      _moderate(alertId, "approve", hours: liveHours);

  /// Reject an alert. [reason]: spam | false | duplicate | low_quality | inappropriate
  static Future<bool> reject(String alertId, String reason) =>
      _moderate(alertId, "reject", reason: reason);

  static Future<bool> _moderate(
    String alertId,
    String decision, {
    String? reason,
    int? hours,
  }) async {
    final client = SupabaseConfig.client;
    if (client == null) return false;
    try {
      await client.rpc("moderate_alert", params: {
        "p_alert_id": alertId,
        "p_decision": decision,
        if (reason != null) "p_reason": reason,
        if (hours != null) "p_hours": hours,
      });
      return true;
    } catch (e) {
      secureLog("[ALERTS] moderate($decision) error: $e");
      return false;
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static List<Alert> _parse(dynamic response) {
    return (response as List).map((row) {
      return Alert.fromJson(Map<String, dynamic>.from(row as Map));
    }).toList();
  }
}
