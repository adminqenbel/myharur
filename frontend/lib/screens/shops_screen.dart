import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';
import '../theme.dart';

class ShopsScreen extends ConsumerStatefulWidget {
  const ShopsScreen({super.key});

  @override
  ConsumerState<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends ConsumerState<ShopsScreen> {
  bool _isLoading = true;
  List<dynamic> _shopsList = [];

  @override
  void initState() {
    super.initState();
    _fetchShops();
  }

  Future<void> _fetchShops() async {
    try {
      final response = await ApiClient.dio.get('/shops/');
      if (mounted) {
        setState(() {
          _shopsList = response.data;
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
            'Marketplace',
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
  
  Widget _buildSkeletonShopCard() {
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
          Container(height: 180, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(AppTheme.cardRadius))),
          Padding(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: double.infinity, height: 24, color: skeletonColor),
                const SizedBox(height: 12),
                Container(width: 150, height: 20, color: skeletonColor),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildShopCard(Map<String, dynamic> shop) {
    final hasImage = shop['logo_url'] != null && (shop['logo_url'] as String).isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
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
                shop['logo_url'],
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            )
          else
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceDark : Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.cardRadius)),
              ),
              child: Center(
                child: Icon(Icons.storefront_rounded, size: 64, color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
              ),
            ),
            
          Padding(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        shop['name'] ?? 'Shop',
                        style: Theme.of(context).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (shop['is_approved'] == true)
                      const Icon(Icons.verified_rounded, color: AppTheme.verified, size: 24),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  shop['description'] ?? 'No description available.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryYellow.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        shop['category'] ?? 'Retail',
                        style: const TextStyle(color: AppTheme.primaryYellow, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 14, color: Theme.of(context).iconTheme.color),
                          const SizedBox(width: 4),
                          Text(
                            shop['address'] ?? 'Harur',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.bookmark_border_rounded, color: Colors.grey),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
              onRefresh: _fetchShops,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  if (_isLoading)
                    ...List.generate(3, (_) => _buildSkeletonShopCard())
                  else if (_shopsList.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text('No shops found.', style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    )
                  else
                    ..._shopsList.map((shop) => _buildShopCard(shop)).toList(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppTheme.primaryYellow,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Shop', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
