import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';
import '../api_client.dart';
import 'news_screen.dart';
import 'emergency_screen.dart';
import 'shops_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  List<dynamic> _latestNews = [];
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(_pulseController);
    _fetchDashboardData();
    _fetchLatestNews();
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final r = await ApiClient.dio.get('/dashboard/home');
      if (mounted) {
        setState(() {
          _dashboardData = r.data as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchLatestNews() async {
    try {
      final r = await ApiClient.dio.get('/news/');
      if (mounted) {
        setState(() {
          _latestNews = (r.data as List).take(3).toList();
        });
      }
    } catch (_) {
      // Handle silently
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildSkeleton(double width, double height, {double radius = AppTheme.cardRadius}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark.withOpacity(0.5) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildCustomHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = ref.watch(authProvider);
    final userDisplayName = auth.displayName;    final greeting = _getGreeting();
    
    return Container(
      height: 120,
      padding: const EdgeInsets.only(top: 40, left: 24, right: 24, bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.primaryDark : AppTheme.bgLight,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                greeting,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryYellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'My Harur',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.search_rounded, color: Theme.of(context).iconTheme.color),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.notifications_rounded, color: Theme.of(context).iconTheme.color),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryYellow,
                child: Text(
                  userDisplayName != null && userDisplayName.isNotEmpty ? userDisplayName.substring(0, 1).toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
  
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildEmergencyBanner() {
    return GestureDetector(
      onTap: () => _navigateTo(const EmergencyScreen()),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        decoration: BoxDecoration(
          color: AppTheme.emergency,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          boxShadow: [
            BoxShadow(
              color: AppTheme.emergency.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Row(
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: const Icon(Icons.warning_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Active Emergency', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 4),
                  Text('Heavy rain expected in Harur at 5 PM', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.dividerColor.withOpacity(isDark ? 0.1 : 0.5)),
            ),
            child: Icon(icon, color: AppTheme.primaryYellow, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildQuickAction(Icons.newspaper_rounded, 'News', () => _navigateTo(const NewsScreen())),
          _buildQuickAction(Icons.storefront_rounded, 'Shops', () => _navigateTo(const ShopsScreen())),
          _buildQuickAction(Icons.chat_bubble_rounded, 'Chat', () => context.go('/community')),
          _buildQuickAction(Icons.handshake_rounded, 'Market', () => context.go('/market')),
        ],
      ),
    );
  }
  
  Widget _buildTownStats() {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: _buildSkeleton(double.infinity, 100),
      );
    }
    
    final stats = _dashboardData['town_statistics'] ?? {};
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: AppTheme.dividerColor.withOpacity(isDark ? 0.1 : 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Town Statistics', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(Icons.people_rounded, stats['citizens']?.toString() ?? '0', 'Citizens'),
              _buildStatItem(Icons.store_rounded, stats['shops']?.toString() ?? '0', 'Shops'),
              _buildStatItem(Icons.article_rounded, stats['news_reports']?.toString() ?? '0', 'Reports'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryYellow, size: 24),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }

  Widget _buildLatestNews() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Latest News', style: Theme.of(context).textTheme.titleLarge),
              TextButton(
                onPressed: () => _navigateTo(const NewsScreen()),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            Column(
              children: List.generate(2, (index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildSkeleton(double.infinity, 240),
              )),
            )
          else if (_latestNews.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No news available.', style: Theme.of(context).textTheme.bodyMedium),
              ),
            )
          else
            ..._latestNews.map((news) => _buildNewsCard(news)).toList(),
        ],
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> news) {
    final hasImage = news['image_url'] != null && (news['image_url'] as String).isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: AppTheme.dividerColor.withOpacity(isDark ? 0.1 : 0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              Image.network(
                news['image_url'],
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryYellow.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          news['location_name'] ?? 'Harur',
                          style: const TextStyle(color: AppTheme.primaryYellow, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (news['is_approved'] == true)
                         const Icon(Icons.verified_rounded, color: AppTheme.verified, size: 16),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    news['title'] ?? 'News Update',
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    news['content'] ?? '',
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        news['source'] ?? 'Local News',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.primaryYellow),
                      ),
                      Text(
                        news['created_at'] != null ? news['created_at'].toString().substring(0, 10) : '',
                        style: Theme.of(context).textTheme.labelSmall,
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
              onRefresh: () async {
                await _fetchDashboardData();
                await _fetchLatestNews();
              },
              child: ListView(
                padding: const EdgeInsets.only(top: 8, bottom: 100),
                children: [
                  _buildEmergencyBanner(),
                  _buildQuickActions(),
                  _buildTownStats(),
                  _buildLatestNews(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
