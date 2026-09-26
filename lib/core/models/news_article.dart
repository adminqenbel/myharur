// ==============================================================================
// NEWS ARTICLE — one headline gathered by the news-crawler edge function.
// Only headline + source + link are stored; the app opens the publisher's site.
// ==============================================================================
class NewsArticle {
  final String id;
  final String title;
  final String url;
  final String? source;
  final String? summary;
  final String category; // traffic | weather | civic | farming | general
  final String region; // harur | dharmapuri | both
  final String language; // en | ta
  final DateTime publishedAt;

  const NewsArticle({
    required this.id,
    required this.title,
    required this.url,
    this.source,
    this.summary,
    required this.category,
    required this.region,
    required this.language,
    required this.publishedAt,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> j) => NewsArticle(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        url: j['url'] as String? ?? '',
        source: j['source'] as String?,
        summary: j['summary'] as String?,
        category: j['category'] as String? ?? 'general',
        region: j['region'] as String? ?? 'both',
        language: j['language'] as String? ?? 'en',
        publishedAt: DateTime.tryParse(j['published_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
      );
}
