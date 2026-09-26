import '../models/news_article.dart';
import 'supabase_config.dart';
import '../util/secure_log.dart';

class NewsService {
  /// Latest headlines, newest first. [category]/[region] are null for "all".
  /// Returns null on error (so the UI can offer a retry) and [] when there is nothing yet.
  static Future<List<NewsArticle>?> fetch({String? category, String? region, int limit = 40}) async {
    final client = SupabaseConfig.client;
    if (client == null) return null;
    try {
      var q = client.from('news_articles').select();
      if (category != null) q = q.eq('category', category);
      if (region != null) q = q.inFilter('region', [region, 'both']);
      final rows = await q.order('published_at', ascending: false).limit(limit);
      return (rows as List).map((r) => NewsArticle.fromJson(r as Map<String, dynamic>)).toList();
    } catch (e) {
      secureLog('[NEWS] fetch error: $e');
      return null;
    }
  }
}
