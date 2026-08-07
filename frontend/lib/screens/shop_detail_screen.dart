import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';

class ShopDetailScreen extends ConsumerWidget {
  final Map<String, dynamic> shop;
  const ShopDetailScreen({super.key, required this.shop});

  Future<void> _launchUrl(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not perform action')),
        );
      }
    }
  }

  void _callShop(BuildContext ctx, String phone) => _launchUrl('tel:$phone', ctx);
  void _whatsappShop(BuildContext ctx, String phone) => _launchUrl('https://wa.me/91$phone', ctx);
  void _directionsTo(BuildContext ctx, double lat, double lng) =>
      _launchUrl('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng', ctx);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOpen = shop['is_open'] == true;
    final isVerified = shop['is_verified'] == true;
    final cat = shop['category'] as Map<String, dynamic>?;
    final products = List<dynamic>.from(shop['products'] ?? []);
    final offers = List<dynamic>.from(shop['offers'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: Text(shop['name'] ?? 'Shop Details'),
        actions: [
          if (isVerified)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded, color: AppTheme.accent, size: 20),
                  const SizedBox(width: 4),
                  Text('Verified', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.accent.withOpacity(0.1), AppTheme.accent.withOpacity(0.02)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: shop['logo_url'] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(40),
                                  child: Image.network(shop['logo_url'], width: 80, height: 80, fit: BoxFit.cover),
                                )
                              : Text(cat?['icon'] ?? '🏪', style: const TextStyle(fontSize: 40)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        shop['name'] ?? '',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      if (cat != null) ...[
                        const SizedBox(height: 4),
                        Text(cat['name'], style: TextStyle(fontSize: 14, color: AppTheme.textSecondaryLight)),
                      ],
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isOpen ? AppTheme.success.withOpacity(0.12) : AppTheme.danger.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isOpen ? 'Currently Open' : 'Currently Closed',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isOpen ? AppTheme.success : AppTheme.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Description
                if (shop['description'] != null)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      shop['description'],
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ),

                // Contact Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      if (shop['phone'] != null)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ElevatedButton.icon(
                              onPressed: () => _callShop(context, shop['phone']),
                              icon: const Icon(Icons.call_rounded),
                              label: const Text('Call'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, foregroundColor: Colors.white),
                            ),
                          ),
                        ),
                      if (shop['whatsapp'] != null)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ElevatedButton.icon(
                              onPressed: () => _whatsappShop(context, shop['whatsapp']),
                              icon: const Icon(Icons.chat_rounded),
                              label: const Text('WhatsApp'),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
                            ),
                          ),
                        ),
                      if (shop['location_lat'] != null && shop['location_lng'] != null)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _directionsTo(context, shop['location_lat'], shop['location_lng']),
                            icon: const Icon(Icons.directions_rounded),
                            label: const Text('Directions'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Info Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      if (shop['address'] != null)
                        _infoCard(Icons.location_on_rounded, 'Address', shop['address'], isDark),
                      if (shop['opening_hours'] != null)
                        _infoCard(Icons.schedule_rounded, 'Hours', shop['opening_hours'], isDark),
                      if (shop['delivery_available'] == true)
                        _infoCard(Icons.delivery_dining_rounded, 'Delivery', 'Home delivery available', isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Offers Section
          if (offers.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text('Special Offers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final o = offers[i];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_offer_rounded, color: Colors.orange, size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(o['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              if (o['discount_percentage'] != null)
                                Text('${o['discount_percentage']}% OFF', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w800, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                childCount: offers.length,
              ),
            ),
          ],

          // Products Section
          if (products.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text('Products & Pricing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final p = products[i];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.inventory_2_rounded, color: AppTheme.accent),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 2),
                              if (p['stock'] != null && p['stock'] > 0)
                                Text('In Stock', style: TextStyle(color: AppTheme.success, fontSize: 12))
                              else
                                const Text('Out of Stock', style: TextStyle(color: AppTheme.danger, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text('₹${p['price']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.accent)),
                      ],
                    ),
                  );
                },
                childCount: products.length,
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String value, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondaryLight, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
