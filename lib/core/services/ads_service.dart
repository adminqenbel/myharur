import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../util/secure_log.dart';
import 'photo_service.dart';
import 'supabase_config.dart';

// ==============================================================================
// ADS — local sponsored cards, managed by a super admin. Never personal: only aggregate impression/click
// counters, no per-viewer tracking. The `ads` table is public-readable (RLS filters to active + in date
// range); every write goes through a SECURITY DEFINER RPC, never a direct table grant.
// ==============================================================================
class Ad {
  final String id;
  final String title;
  final String body;
  final String? imagePath; // path in the public `ad-images` bucket, or null
  final String linkUrl;
  final String placement; // home | news | reports
  final int priority;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String status; // draft | active | paused
  final int impressions;
  final int clicks;
  final DateTime createdAt;

  const Ad({
    required this.id,
    required this.title,
    required this.body,
    this.imagePath,
    required this.linkUrl,
    required this.placement,
    required this.priority,
    required this.startsAt,
    this.endsAt,
    required this.status,
    this.impressions = 0,
    this.clicks = 0,
    required this.createdAt,
  });

  /// A public bucket: the URL is the same for everyone, no signing needed.
  String? get imageUrl => imagePath == null ? null : '${SupabaseConfig.url}/storage/v1/object/public/ad-images/$imagePath';

  factory Ad.fromJson(Map<String, dynamic> j) => Ad(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        imagePath: j['image_path'] as String?,
        linkUrl: j['link_url'] as String? ?? '',
        placement: j['placement'] as String? ?? 'home',
        priority: (j['priority'] as num?)?.toInt() ?? 0,
        startsAt: DateTime.tryParse(j['starts_at'] as String? ?? '') ?? DateTime.now(),
        endsAt: j['ends_at'] != null ? DateTime.tryParse(j['ends_at'] as String) : null,
        status: j['status'] as String? ?? 'draft',
        impressions: (j['impressions'] as num?)?.toInt() ?? 0,
        clicks: (j['clicks'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}

class AdsService {
  static SupabaseClient? get _c => SupabaseConfig.client;

  /// Active ads for one placement, highest priority first. Empty (not null) when there are none or the
  /// call fails — a missing ad must never block the feed it decorates.
  static Future<List<Ad>> activeAds(String placement, {int limit = 5}) async {
    try {
      final rows = await _c?.from('ads').select().eq('placement', placement).order('priority', ascending: false).limit(limit);
      if (rows == null) return const [];
      return (rows as List).map((r) => Ad.fromJson(Map<String, dynamic>.from(r as Map))).toList();
    } catch (e) {
      secureLog('[ADS] activeAds error: $e');
      return const [];
    }
  }

  static Future<void> recordImpression(String id) => _record(id, 'impression');
  static Future<void> recordClick(String id) => _record(id, 'click');

  static Future<void> _record(String id, String kind) async {
    try {
      await _c?.rpc('record_ad_event', params: {'p_id': id, 'p_kind': kind});
    } catch (e) {
      secureLog('[ADS] record $kind failed: $e'); // never blocks the tap/impression itself
    }
  }

  // ── admin ────────────────────────────────────────────────────────────────────

  static Future<List<Ad>?> adminList() async {
    try {
      final rows = await _c?.rpc('admin_list_ads');
      if (rows == null) return null;
      return (rows as List).map((r) => Ad.fromJson(Map<String, dynamic>.from(r as Map))).toList();
    } catch (e) {
      secureLog('[ADS] adminList error: $e');
      return null;
    }
  }

  /// Uploads a prepared (already compressed) image to the public ad-images bucket. Returns the path, or
  /// null on failure. Reuses [PhotoService.prepare] so ad creatives get the same size/EXIF handling.
  static Future<String?> uploadImage(Uint8List jpeg) async {
    final client = _c;
    if (client == null) return null;
    final path = 'ads/${PhotoService.uuid4()}.jpg';
    try {
      await client.storage.from('ad-images').uploadBinary(path, jpeg, fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false));
      return path;
    } catch (e) {
      secureLog('[ADS] uploadImage error: $e');
      return null;
    }
  }

  /// Returns null on success, otherwise a code: aal2_required | forbidden | failed.
  static Future<String?> create({
    required String title,
    required String body,
    String? imagePath,
    required String link,
    required String placement,
    int priority = 0,
    required DateTime startsAt,
    DateTime? endsAt,
  }) async {
    final client = _c;
    if (client == null) return 'network';
    try {
      await client.rpc('admin_create_ad', params: {
        'p_title': title.trim(),
        'p_body': body.trim(),
        'p_image_path': imagePath,
        'p_link': link.trim(),
        'p_placement': placement,
        'p_priority': priority,
        'p_starts_at': startsAt.toUtc().toIso8601String(),
        'p_ends_at': endsAt?.toUtc().toIso8601String(),
      });
      return null;
    } on PostgrestException catch (e) {
      if (e.message.contains('aal2_required')) return 'aal2_required';
      if (e.message.contains('forbidden')) return 'forbidden';
      return 'failed';
    } catch (e) {
      secureLog('[ADS] create error: $e');
      return 'failed';
    }
  }

  static Future<bool> setStatus(String id, String status) async {
    try {
      await _c?.rpc('admin_set_ad_status', params: {'p_id': id, 'p_status': status});
      return true;
    } catch (e) {
      secureLog('[ADS] setStatus error: $e');
      return false;
    }
  }

  static Future<bool> delete(String id) async {
    try {
      await _c?.rpc('admin_delete_ad', params: {'p_id': id});
      return true;
    } catch (e) {
      secureLog('[ADS] delete error: $e');
      return false;
    }
  }
}
