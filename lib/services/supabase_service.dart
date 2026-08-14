import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String defaultUrl = 'https://YOUR_PROJECT_REF.supabase.co';
  static const String defaultAnonKey = 'YOUR_ANON_KEY';

  static String _activeUrl = defaultUrl;
  static bool _isInitialized = false;

  static bool get isConfigured =>
      _isInitialized &&
      _activeUrl != defaultUrl &&
      !_activeUrl.contains('YOUR_PROJECT_REF');

  static Future<void> initialize({String? url, String? anonKey}) async {
    final targetUrl = url ?? const String.fromEnvironment('SUPABASE_URL', defaultValue: defaultUrl);
    final targetKey = anonKey ?? const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: defaultAnonKey);

    if (targetUrl != defaultUrl) {
      try {
        await Supabase.initialize(
          url: targetUrl,
          anonKey: targetKey,
        );
        _activeUrl = targetUrl;
        _isInitialized = true;
      } catch (_) {
        // Fallback gracefully if already initialized or offline
      }
    }
  }

  static SupabaseClient? get client => _isInitialized ? Supabase.instance.client : null;
}

/// Service handling local news items and submissions
class NewsService {
  static Future<List<Map<String, dynamic>>> fetchApprovedNews({int limit = 20}) async {
    final client = SupabaseConfig.client;
    if (client == null) return [];

    try {
      final response = await client
          .from('news_items')
          .select()
          .eq('status', 'published')
          .order('published_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  static Future<bool> submitNews({
    required String title,
    required String content,
    String? sourceUrl,
    String? category,
  }) async {
    final client = SupabaseConfig.client;
    if (client == null) return false;

    try {
      await client.from('news_submissions').insert({
        'title': title,
        'content': content,
        'source_url': sourceUrl,
        'category': category ?? 'Civic',
        'status': 'pending',
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Service handling emergency requests and alerts
class EmergencyService {
  static Future<String?> broadcastEmergency({
    required String emergencyType,
    required double latitude,
    required double longitude,
    required int radiusKm,
    String? description,
  }) async {
    final client = SupabaseConfig.client;
    if (client == null) return null;

    try {
      final res = await client.functions.invoke(
        'create-emergency',
        body: {
          'emergency_type': emergencyType,
          'latitude': latitude,
          'longitude': longitude,
          'radius_km': radiusKm,
          'description': description,
        },
      );
      return res.data?['emergency_id'] as String?;
    } catch (_) {
      return null;
    }
  }
}

/// Service for weather snapshots and observations
class WeatherService {
  static Future<Map<String, dynamic>?> getLatestSnapshot(String locationName) async {
    final client = SupabaseConfig.client;
    if (client == null) return null;

    try {
      final response = await client
          .from('weather_snapshots')
          .select()
          .eq('location_name', locationName)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (_) {
      return null;
    }
  }
}

/// Service for Marketplace listings
class MarketplaceService {
  static Future<List<Map<String, dynamic>>> fetchListings({String? category}) async {
    final client = SupabaseConfig.client;
    if (client == null) return [];

    try {
      var query = client.from('marketplace_listings').select().eq('is_sold', false);
      if (category != null && category != 'All') {
        query = query.eq('category', category);
      }
      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  static Future<bool> createListing({
    required String title,
    required String description,
    required double price,
    required String condition,
    required String category,
    String? phone,
  }) async {
    final client = SupabaseConfig.client;
    if (client == null) return false;

    try {
      await client.from('marketplace_listings').insert({
        'title': title,
        'description': description,
        'price': price,
        'condition': condition,
        'category': category,
        'contact_phone': phone,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Service for Governance, 3-Admin consensus, and Moderation
class GovernanceService {
  static Future<Map<String, dynamic>?> voteTerminateUser({
    required String targetUserId,
    required String reason,
  }) async {
    final client = SupabaseConfig.client;
    if (client == null) return null;

    try {
      final res = await client.functions.invoke(
        'admin-governance',
        body: {
          'action': 'vote_terminate',
          'targetUserId': targetUserId,
          'reason': reason,
        },
      );
      return res.data;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> superAdminTerminate({
    required String targetUserId,
    required String reason,
  }) async {
    final client = SupabaseConfig.client;
    if (client == null) return null;

    try {
      final res = await client.functions.invoke(
        'admin-governance',
        body: {
          'action': 'superadmin_terminate',
          'targetUserId': targetUserId,
          'reason': reason,
        },
      );
      return res.data;
    } catch (_) {
      return null;
    }
  }
}
