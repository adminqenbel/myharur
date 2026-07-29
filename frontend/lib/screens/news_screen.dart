import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api_client.dart';
import '../theme.dart';
import '../providers/auth_provider.dart';

class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen> {
  bool _isLoading = true;
  List<dynamic> _newsList = [];

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    try {
      final response = await ApiClient.dio.get('/news/');
      if (mounted) {
        setState(() {
          _newsList = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildCustomHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 120,
      padding: const EdgeInsets.only(top: 40, left: 16, right: 24, bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.primaryDark : AppTheme.bgLight,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).iconTheme.color),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            'News',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: isDark ? Colors.white : AppTheme.primaryDark,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.search_rounded, color: Theme.of(context).iconTheme.color),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonNewsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final skeletonColor = isDark ? AppTheme.surfaceDark.withOpacity(0.5) : Colors.grey.shade200;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.dividerColor.withOpacity(isDark ? 0.1 : 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 200, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(AppTheme.cardRadius))),
          Padding(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 100, height: 24, color: skeletonColor),
                const SizedBox(height: 12),
                Container(width: double.infinity, height: 20, color: skeletonColor),
                const SizedBox(height: 8),
                Container(width: 200, height: 20, color: skeletonColor),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> news) {
    final hasImage = news['image_url'] != null && (news['image_url'] as String).isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () async {
        if (news['url'] != null) {
          final Uri url = Uri.parse(news['url']);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          boxShadow: AppTheme.softShadow,
          border: Border.all(color: AppTheme.dividerColor.withOpacity(isDark ? 0.1 : 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.cardRadius)),
                child: Image.network(
                  news['image_url'],
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryYellow.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          news['category'] ?? 'General',
                          style: const TextStyle(color: AppTheme.primaryYellow, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on_rounded, size: 14, color: Theme.of(context).iconTheme.color),
                            const SizedBox(width: 4),
                            Text(
                              news['location_name'] ?? 'Harur',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (news['is_approved'] == true)
                        const Icon(Icons.verified_rounded, color: AppTheme.verified, size: 20),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    news['title'] ?? 'News Update',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    news['content'] ?? '',
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        news['source'] ?? 'Local Reporter',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      const Text('•', style: TextStyle(color: Colors.grey)),
                      const SizedBox(width: 8),
                      Text(
                        news['created_at'] != null ? news['created_at'].toString().substring(0, 10) : 'Today',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.translate_rounded, size: 20, color: Colors.grey),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.bookmark_border_rounded, size: 20, color: Colors.grey),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_rounded, size: 20, color: Colors.grey),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildCustomHeader(),
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primaryYellow,
              onRefresh: _fetchNews,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  if (_isLoading)
                    ...List.generate(3, (_) => _buildSkeletonNewsCard())
                  else if (_newsList.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text('No news available.', style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    )
                  else
                    ..._newsList.map((news) => _buildNewsCard(news)).toList(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: ref.watch(authProvider).isLoggedIn ? FloatingActionButton.extended(
        onPressed: () {}, // Trigger submit news modal
        backgroundColor: AppTheme.primaryYellow,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Report News', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ) : null,
    );
  }
}
