import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api_client.dart';
import '../theme.dart';
import 'shop_registration_screen.dart';

class MyShopsScreen extends ConsumerStatefulWidget {
  const MyShopsScreen({super.key});

  @override
  ConsumerState<MyShopsScreen> createState() => _MyShopsScreenState();
}

class _MyShopsScreenState extends ConsumerState<MyShopsScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _shops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyShops();
  }

  Future<void> _fetchMyShops() async {
    setState(() => _isLoading = true);
    try {
      final r = await ApiClient.dio.get('/shops/my-shops');
      if (mounted) {
        setState(() {
          _shops = r.data as List;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleOpen(int shopId, bool currentlyOpen) async {
    try {
      await ApiClient.dio.put('/shops/$shopId/toggle-open');
      _fetchMyShops();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: AppTheme.danger,
        ));
      }
    }
  }

  Future<void> _deleteShop(int shopId, String shopName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Shop?'),
        content: Text('Are you sure you want to delete "$shopName"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiClient.dio.delete('/shops/$shopId');
      _fetchMyShops();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Shop deleted'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.danger,
        ));
      }
    }
  }

  void _openProductManager(Map<String, dynamic> shop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ProductManagerSheet(shop: shop, onRefresh: _fetchMyShops),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shops'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _fetchMyShops),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ShopRegistrationScreen()),
        ).then((_) => _fetchMyShops()),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Shop'),
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _shops.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _fetchMyShops,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _shops.length,
                    itemBuilder: (ctx, i) => _buildShopCard(_shops[i], isDark),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.store_mall_directory_outlined, size: 60, color: AppTheme.accent),
          ),
          const SizedBox(height: 20),
          const Text('No Shops Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Register your business on MyHarur\nand reach thousands of local customers.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShopRegistrationScreen()),
            ).then((_) => _fetchMyShops()),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Register a Shop'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopCard(Map<String, dynamic> shop, bool isDark) {
    final isApproved = shop['is_approved'] == true;
    final isVerified = shop['is_verified'] == true;
    final isOpen = shop['is_open'] == true;
    final cat = shop['category'] as Map<String, dynamic>?;
    final products = (shop['products'] as List?)?.length ?? 0;
    final visits = shop['visit_count'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isApproved
              ? (isDark ? AppTheme.dividerDark : AppTheme.dividerLight)
              : Colors.orange.withOpacity(0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isApproved
                    ? [AppTheme.accent.withOpacity(0.15), AppTheme.accent.withOpacity(0.05)]
                    : [Colors.orange.withOpacity(0.15), Colors.orange.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Text(cat?['icon'] ?? '🏪', style: const TextStyle(fontSize: 32)),
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
                            ),
                          ),
                          if (isVerified)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.accent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_rounded, color: Colors.white, size: 12),
                                  SizedBox(width: 3),
                                  Text('Verified', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (cat != null) ...[
                            Text(cat['name'], style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight)),
                            const SizedBox(width: 8),
                            Container(width: 3, height: 3, decoration: BoxDecoration(color: AppTheme.textSecondary, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isApproved ? AppTheme.success.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isApproved ? 'Live' : 'Pending Review',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isApproved ? AppTheme.success : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _statPill(Icons.remove_red_eye_rounded, '$visits views', Colors.purple),
                const SizedBox(width: 10),
                _statPill(Icons.inventory_2_rounded, '$products products', AppTheme.accent),
                const Spacer(),
                // Open/Close toggle
                GestureDetector(
                  onTap: () => _toggleOpen(shop['id'] as int, isOpen),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isOpen ? AppTheme.success.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isOpen ? AppTheme.success.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isOpen ? AppTheme.success : AppTheme.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOpen ? 'Open' : 'Closed',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isOpen ? AppTheme.success : AppTheme.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Address
          if (shop['address'] != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 14, color: AppTheme.textSecondaryLight),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      shop['address'],
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          const Divider(height: 1),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                _actionButton(Icons.inventory_2_rounded, 'Products', () => _openProductManager(shop)),
                _actionButton(Icons.local_offer_rounded, 'Offers', () => _openOffersManager(shop)),
                _actionButton(Icons.edit_rounded, 'Edit', () => _editShop(shop)),
                _actionButton(Icons.delete_rounded, 'Delete', () => _deleteShop(shop['id'] as int, shop['name'] as String), color: AppTheme.danger),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    final c = color ?? AppTheme.accent;
    return Expanded(
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: c),
        label: Text(label, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600)),
        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
      ),
    );
  }

  void _openOffersManager(Map<String, dynamic> shop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _OffersManagerSheet(shop: shop, onRefresh: _fetchMyShops),
    );
  }

  void _editShop(Map<String, dynamic> shop) {
    // TODO: navigate to edit screen (can reuse registration with pre-fill)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit shop coming soon!'), behavior: SnackBarBehavior.floating),
    );
  }
}

// ─── Product Manager Bottom Sheet ────────────────────────────────────────────

class _ProductManagerSheet extends StatefulWidget {
  final Map<String, dynamic> shop;
  final VoidCallback onRefresh;
  const _ProductManagerSheet({required this.shop, required this.onRefresh});

  @override
  State<_ProductManagerSheet> createState() => _ProductManagerSheetState();
}

class _ProductManagerSheetState extends State<_ProductManagerSheet> {
  List<dynamic> _products = [];
  bool _showForm = false;
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _products = List<dynamic>.from(widget.shop['products'] ?? []);
  }

  Future<void> _addProduct() async {
    if (_nameCtrl.text.trim().isEmpty || _priceCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final r = await ApiClient.dio.post('/shops/${widget.shop['id']}/products', data: {
        'name': _nameCtrl.text.trim(),
        'price': double.parse(_priceCtrl.text.trim()),
        'stock': int.tryParse(_stockCtrl.text.trim()) ?? 0,
      });
      setState(() {
        _products.add(r.data);
        _showForm = false;
        _nameCtrl.clear();
        _priceCtrl.clear();
        _stockCtrl.clear();
        _saving = false;
      });
      widget.onRefresh();
    } catch (_) {
      setState(() => _saving = false);
    }
  }

  Future<void> _deleteProduct(int productId) async {
    try {
      await ApiClient.dio.delete('/shops/${widget.shop['id']}/products/$productId');
      setState(() => _products.removeWhere((p) => p['id'] == productId));
      widget.onRefresh();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, scroll) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                const Text('Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(() => _showForm = !_showForm),
                  icon: Icon(_showForm ? Icons.close_rounded : Icons.add_rounded),
                  label: Text(_showForm ? 'Cancel' : 'Add'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
                ),
              ],
            ),
          ),
          if (_showForm)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Product Name *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Price (₹) *', border: OutlineInputBorder(), prefixText: '₹'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _stockCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Stock', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _addProduct,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.white),
                      child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Add Product'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          Expanded(
            child: _products.isEmpty
                ? Center(child: Text('No products yet. Add your first product!', style: TextStyle(color: AppTheme.textSecondary)))
                : ListView.builder(
                    controller: scroll,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _products.length,
                    itemBuilder: (ctx, i) {
                      final p = _products[i];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.inventory_2_rounded, color: AppTheme.accent, size: 20),
                        ),
                        title: Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('₹${p['price']} • Stock: ${p['stock'] ?? 0}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_rounded, color: AppTheme.danger),
                          onPressed: () => _deleteProduct(p['id'] as int),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Offers Manager Bottom Sheet ─────────────────────────────────────────────

class _OffersManagerSheet extends StatefulWidget {
  final Map<String, dynamic> shop;
  final VoidCallback onRefresh;
  const _OffersManagerSheet({required this.shop, required this.onRefresh});

  @override
  State<_OffersManagerSheet> createState() => _OffersManagerSheetState();
}

class _OffersManagerSheetState extends State<_OffersManagerSheet> {
  List<dynamic> _offers = [];
  bool _showForm = false;
  final _titleCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _offers = List<dynamic>.from(widget.shop['offers'] ?? []);
  }

  Future<void> _addOffer() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final r = await ApiClient.dio.post('/shops/${widget.shop['id']}/offers', data: {
        'title': _titleCtrl.text.trim(),
        'discount_percentage': double.tryParse(_discountCtrl.text.trim()),
      });
      setState(() {
        _offers.add(r.data);
        _showForm = false;
        _titleCtrl.clear();
        _discountCtrl.clear();
        _saving = false;
      });
      widget.onRefresh();
    } catch (_) {
      setState(() => _saving = false);
    }
  }

  Future<void> _deleteOffer(int offerId) async {
    try {
      await ApiClient.dio.delete('/shops/${widget.shop['id']}/offers/$offerId');
      setState(() => _offers.removeWhere((o) => o['id'] == offerId));
      widget.onRefresh();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.35,
      expand: false,
      builder: (ctx, scroll) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                const Text('Special Offers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(() => _showForm = !_showForm),
                  icon: Icon(_showForm ? Icons.close_rounded : Icons.add_rounded),
                  label: Text(_showForm ? 'Cancel' : 'Add'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
                ),
              ],
            ),
          ),
          if (_showForm)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(labelText: 'Offer Title *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _discountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Discount %', border: OutlineInputBorder(), suffixText: '%'),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _addOffer,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                      child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Add Offer'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          Expanded(
            child: _offers.isEmpty
                ? Center(child: Text('No offers yet.', style: TextStyle(color: AppTheme.textSecondary)))
                : ListView.builder(
                    controller: scroll,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _offers.length,
                    itemBuilder: (ctx, i) {
                      final o = _offers[i];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.local_offer_rounded, color: Colors.orange, size: 20),
                        ),
                        title: Text(o['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: o['discount_percentage'] != null ? Text('${o['discount_percentage']}% off') : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_rounded, color: AppTheme.danger),
                          onPressed: () => _deleteOffer(o['id'] as int),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
