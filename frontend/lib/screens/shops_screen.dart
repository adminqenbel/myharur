import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api_client.dart';
import '../theme.dart';
import 'shop_registration_screen.dart';
import 'my_shops_screen.dart';
import 'shop_detail_screen.dart';

class ShopsScreen extends ConsumerStatefulWidget {
  const ShopsScreen({super.key});

  @override
  ConsumerState<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends ConsumerState<ShopsScreen> {
  List<dynamic> _shops = [];
  List<dynamic> _categories = [];
  bool _isLoading = true;
  String? _error;
  int? _selectedCategoryId;
  String _sort = 'newest';
  final _searchCtrl = TextEditingController();
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiClient.dio.get('/shops/categories'),
        ApiClient.dio.get('/shops/', queryParameters: {
          if (_selectedCategoryId != null) 'category_id': _selectedCategoryId,
          'sort': _sort,
          if (_searchCtrl.text.trim().isNotEmpty) 'q': _searchCtrl.text.trim(),
        }),
      ]);
      if (mounted) {
        setState(() {
          _categories = results[0].data as List;
          _shops = results[1].data as List;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load shops. Check your connection.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _filterByCategory(int? catId) async {
    setState(() => _selectedCategoryId = catId);
    await _loadData();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _callShop(String phone) => _launchUrl('tel:$phone');
  void _whatsappShop(String phone) => _launchUrl('https://wa.me/91$phone');
  void _directionsTo(double lat, double lng) =>
      _launchUrl('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Businesses'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              setState(() {
                _searching = !_searching;
                if (!_searching) {
                  _searchCtrl.clear();
                  _loadData();
                }
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: (val) {
              setState(() => _sort = val);
              _loadData();
            },
            icon: const Icon(Icons.sort_rounded),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'newest', child: Text('Newest First')),
              const PopupMenuItem(value: 'popular', child: Text('Most Popular')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.storefront_rounded),
            tooltip: 'My Shops',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyShopsScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ShopRegistrationScreen()),
        ).then((_) => _loadData()),
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Register Shop'),
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Search bar
          if (_searching)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search shops...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            _loadData();
                          },
                        )
                      : null,
                ),
                onSubmitted: (_) => _loadData(),
                onChanged: (v) {
                  if (v.isEmpty) _loadData();
                  setState(() {});
                },
              ),
            ),

          // Category chips
          if (_categories.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.bgDark : AppTheme.bgLight,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    _categoryChip(null, '🏪', 'All', isDark),
                    const SizedBox(width: 8),
                    ..._categories.map((cat) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _categoryChip(
                            cat['id'] as int,
                            cat['icon'] ?? '🏪',
                            cat['name'] as String,
                            isDark,
                          ),
                        )),
                  ],
                ),
              ),
            ),

          // Shop list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : _shops.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            child: ListView.builder(
                              padding: const EdgeInsets.only(top: 12, bottom: 120),
                              itemCount: _shops.length,
                              itemBuilder: (ctx, i) => _buildShopCard(_shops[i], isDark),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(int? id, String icon, String label, bool isDark) {
    final isSelected = _selectedCategoryId == id;
    return GestureDetector(
      onTap: () => _filterByCategory(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accent : (isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.accent : (isDark ? AppTheme.dividerDark : AppTheme.dividerLight),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 5),
            Text(
              label.length > 12 ? '${label.substring(0, 10)}…' : label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopCard(Map<String, dynamic> shop, bool isDark) {
    final isOpen = shop['is_open'] == true;
    final isVerified = shop['is_verified'] == true;
    final cat = shop['category'] as Map<String, dynamic>?;
    final phone = shop['phone'] as String?;
    final whatsapp = shop['whatsapp'] as String?;
    final lat = shop['location_lat'] as double?;
    final lng = shop['location_lng'] as double?;
    final products = (shop['products'] as List?)?.length ?? 0;
    final offers = (shop['offers'] as List?)?.length ?? 0;

    return GestureDetector(
      onTap: () {
        // We will push the detail screen directly or via GoRouter.
        // For now, push directly to avoid complex GoRouter setup for a sub-screen.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShopDetailScreen(shop: shop),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shop header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo/Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: shop['logo_url'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              shop['logo_url'],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Text(
                                cat?['icon'] ?? '🏪',
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          )
                        : Text(cat?['icon'] ?? '🏪', style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              shop['name'] ?? '',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified_rounded, color: AppTheme.accent, size: 18),
                          ],
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: isOpen ? AppTheme.success.withOpacity(0.12) : AppTheme.danger.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isOpen ? 'Open' : 'Closed',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isOpen ? AppTheme.success : AppTheme.danger,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (cat != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          cat['name'],
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight),
                        ),
                      ],
                      if (shop['description'] != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          shop['description'],
                          style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87, height: 1.3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Info row (address, hours, products, offers)
          if (shop['address'] != null || shop['opening_hours'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              child: Column(
                children: [
                  if (shop['address'] != null)
                    _infoRow(Icons.location_on_rounded, shop['address'], Colors.red),
                  if (shop['opening_hours'] != null)
                    _infoRow(Icons.schedule_rounded, shop['opening_hours'], Colors.orange),
                ],
              ),
            ),

          // Products/Offers pills
          if (products > 0 || offers > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  if (products > 0)
                    _pill('$products Products', AppTheme.accent),
                  if (offers > 0)
                    _pill('$offers Offers 🔥', Colors.orange),
                ],
              ),
            ),

          const Divider(height: 1),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                if (phone != null)
                  Expanded(
                    child: _actionBtn(
                      Icons.call_rounded,
                      'Call',
                      Colors.green,
                      () => _callShop(phone),
                    ),
                  ),
                if (whatsapp != null)
                  Expanded(
                    child: _actionBtn(
                      Icons.chat_rounded,
                      'WhatsApp',
                      const Color(0xFF25D366),
                      () => _whatsappShop(whatsapp),
                    ),
                  ),
                if (lat != null && lng != null)
                  Expanded(
                    child: _actionBtn(
                      Icons.directions_rounded,
                      'Directions',
                      AppTheme.accent,
                      () => _directionsTo(lat, lng),
                    ),
                  ),
                if (phone == null && whatsapp == null && (lat == null || lng == null))
                  Expanded(
                    child: _actionBtn(
                      Icons.info_outline_rounded,
                      'View Details',
                      AppTheme.accent,
                      () {},
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color.withOpacity(0.7)),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4)),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.store_mall_directory_outlined, size: 60, color: AppTheme.danger),
          const SizedBox(height: 16),
          const Text('Failed to Load', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondaryLight)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.storefront_rounded, size: 56, color: AppTheme.accent),
          ),
          const SizedBox(height: 20),
          const Text('No Shops Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            _selectedCategoryId != null
                ? 'No shops in this category yet.'
                : 'Be the first to register your business!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondaryLight),
          ),
          const SizedBox(height: 20),
          if (_selectedCategoryId != null)
            TextButton(
              onPressed: () => _filterByCategory(null),
              child: const Text('Show All Shops'),
            ),
        ],
      ),
    );
  }
}
