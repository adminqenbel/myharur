import "package:flutter/foundation.dart";
import "supabase_config.dart";
import "../models/alert.dart";

// ==============================================================================
// ALERTS SERVICE — v1 core launch surface
// ==============================================================================
class AlertsService {
  /// Fetch published alerts + pending community alerts (for in-feed visibility)
  static Future<List<Alert>> fetchFeedAlerts({
    String? category,
    int? wardId,
    int limit = 30,
  }) async {
    final client = SupabaseConfig.client;
    if (client == null) return [];

    try {
      var filterQuery = client
          .from("alerts")
          .select("""
            id, category, ward_id, title, body, source, status,
            published_as_role, created_by_uid, expires_at,
            emergency_tagged, created_at,
            wards(name)
          """)
          .inFilter("status", ["published", "pending"]);

      if (category != null) {
        filterQuery = filterQuery.eq("category", category);
      }
      if (wardId != null) {
        filterQuery = filterQuery.eq("ward_id", wardId);
      }

      final response = await filterQuery
          .order("emergency_tagged", ascending: false)
          .order("created_at", ascending: false)
          .limit(limit);

      return (response as List).map((row) {
        final wardName = row["wards"]?["name"] as String?;
        return Alert.fromJson({...row, "ward_name": wardName});
      }).toList();
    } catch (e) {
      debugPrint("[ALERTS] fetchFeedAlerts error: $e");
      return [];
    }
  }

  /// Submit a community alert (goes to pending + moderation queue)
  static Future<bool> submitCommunityAlert({
    required String category,
    required String title,
    required String body,
    int? wardId,
    bool emergencyTagged = false,
    String? createdByUid,
  }) async {
    final client = SupabaseConfig.client;
    if (client == null) return false;

    try {
      final alertData = {
        "category": category,
        "title": title.trim(),
        "body": body.trim(),
        "ward_id": wardId,
        "source": "community",
        "status": "pending",
        "emergency_tagged": emergencyTagged,
        "created_by_uid": createdByUid,
      };

      final alertRes = await client.from("alerts").insert(alertData).select().single();

      // Create moderation queue entry
      await client.from("moderation_queue").insert({
        "alert_id": alertRes["id"],
        "category": category,
        "ward_id": wardId,
        "emergency_tagged": emergencyTagged,
        "flagged_by_system": false,
      });

      return true;
    } catch (e) {
      debugPrint("[ALERTS] submitCommunityAlert error: $e");
      return false;
    }
  }

  /// Publish an official alert (admin/superadmin only — enforced by RLS)
  static Future<bool> publishOfficialAlert({
    required String category,
    required String title,
    required String body,
    int? wardId,
    required String publishedAsRole,
    String? createdByUid,
    Duration? expiresIn,
  }) async {
    final client = SupabaseConfig.client;
    if (client == null) return false;

    try {
      await client.from("alerts").insert({
        "category": category,
        "title": title.trim(),
        "body": body.trim(),
        "ward_id": wardId,
        "source": "official",
        "status": "published",
        "published_as_role": publishedAsRole,
        "created_by_uid": createdByUid,
        "expires_at": expiresIn != null
            ? DateTime.now().add(expiresIn).toIso8601String()
            : null,
        "emergency_tagged": false,
      });
      return true;
    } catch (e) {
      debugPrint("[ALERTS] publishOfficialAlert error: $e");
      return false;
    }
  }

  /// Fetch single alert by ID
  static Future<Alert?> fetchById(String alertId) async {
    final client = SupabaseConfig.client;
    if (client == null) return null;
    try {
      final res = await client
          .from("alerts")
          .select("*, wards(name)")
          .eq("id", alertId)
          .maybeSingle();
      if (res == null) return null;
      final wardName = res["wards"]?["name"] as String?;
      return Alert.fromJson({...res, "ward_name": wardName});
    } catch (e) {
      debugPrint("[ALERTS] fetchById error: $e");
      return null;
    }
  }
}