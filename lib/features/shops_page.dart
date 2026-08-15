import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/supabase_service.dart';

class ShopsPage extends StatefulWidget {
  const ShopsPage({super.key});

  @override
  State<ShopsPage> createState() => _ShopsPageState();
}

class _ShopsPageState extends State<ShopsPage> {
  int selectedCategory = 0;
  final categories = ['All', 'Groceries & Agro', 'Electronics', 'Textiles & Silk', 'Sweets & Bakery'];
  List<Map<String, dynamic>> shops = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    setState(() => isLoading = true);
    final category = categories[selectedCategory];
    final data = await ShopsService.fetchShops(category: category);
    if (mounted) {
      setState(() {
        shops = data;
        isLoading = false;
      });
    }
  }

  void _openRegisterShopSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _RegisterShopSheet(onCreated: _loadShops),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = selectedCategory == 0
        ? shops
        : shops.where((s) => s['category'] == categories[selectedCategory]).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Harur Local Shops',
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF15211F)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF15211F), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final active = selectedCategory == i;
                  return ChoiceChip(
                    label: Text(categories[i]),
                    selected: active,
                    onSelected: (_) => setState(() => selectedCategory = i),
                    selectedColor: const Color(0xFF007F63),
                    backgroundColor: const Color(0xFFF2F6F5),
                    labelStyle: TextStyle(
                      color: active ? Colors.white : const Color(0xFF15211F),
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide(
                      color: active ? const Color(0xFF007F63) : const Color(0xFFDCE5E1),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, i) {
                  final shop = filtered[i];
                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFDCE5E1)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x080F2922), blurRadius: 14, offset: Offset(0, 5))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (shop['color'] as Color).withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: SvgPicture.asset(
                                'assets/icons/store.svg',
                                width: 24,
                                height: 24,
                                colorFilter: ColorFilter.mode(shop['color'] as Color, BlendMode.srcIn),
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
                                          shop['name'],
                                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF15211F)),
                                        ),
                                      ),
                                      const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF007F63)),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(shop['category'], style: const TextStyle(fontSize: 12, color: Color(0xFF697570), fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF697570)),
                            const SizedBox(width: 4),
                            Expanded(child: Text(shop['address'], style: const TextStyle(fontSize: 12, color: Color(0xFF697570)))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 4),
                            Text(shop['rating'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF15211F))),
                            const Spacer(),
                            Text('${shop['productsCount']} Items in catalog', style: const TextStyle(fontSize: 12, color: Color(0xFF007F63), fontWeight: FontWeight.w800)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF007F63),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                                label: const Text('Storefront', style: TextStyle(fontWeight: FontWeight.w800)),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Opening ${shop['name']} catalog...')),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFE8F5E9),
                                foregroundColor: const Color(0xFF2E7D32),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                              tooltip: 'WhatsApp Shop',
                              onPressed: () async {
                                final uri = Uri.parse('https://wa.me/91${shop['phone']}?text=Hello+${Uri.encodeComponent(shop['name'])},+inquiring+from+MyHarur+app.');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFE3F2FD),
                                foregroundColor: const Color(0xFF1976D2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: const Icon(Icons.directions_outlined, size: 18),
                              tooltip: 'Directions in Harur',
                              onPressed: () async {
                                final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=Harur+${Uri.encodeComponent("${shop['name']} ${shop['address']}")}');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFF2F6F5),
                                foregroundColor: const Color(0xFF15211F),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: const Icon(Icons.call_rounded, size: 18),
                              tooltip: 'Call Shop',
                              onPressed: () async {
                                final uri = Uri.parse('tel:${shop['phone']}');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF007F63),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Register Shop (Max 2)', style: TextStyle(fontWeight: FontWeight.w800)),
        onPressed: _openRegisterShopSheet,
      ),
    );
  }
}

class _RegisterShopSheet extends StatefulWidget {
  final VoidCallback? onCreated;
  const _RegisterShopSheet({this.onCreated});

  @override
  State<_RegisterShopSheet> createState() => _RegisterShopSheetState();
}

class _RegisterShopSheetState extends State<_RegisterShopSheet> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String selectedCategory = 'Groceries & Agro';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCE5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Register Local Shop Storefront',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF15211F)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Shop Admins can maintain up to 2 shops with products, bulk rates, and offers. Additional stores require Super Admin grant.',
              style: TextStyle(fontSize: 12, color: Color(0xFF697570)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Business / Shop Name',
                filled: true,
                fillColor: const Color(0xFFF2F6F5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressCtrl,
              decoration: InputDecoration(
                labelText: 'Shop Address in Harur',
                filled: true,
                fillColor: const Color(0xFFF2F6F5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Business Contact Number',
                filled: true,
                fillColor: const Color(0xFFF2F6F5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007F63),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  final name = _nameCtrl.text.trim();
                  final address = _addressCtrl.text.trim();
                  final phone = _phoneCtrl.text.trim();
                  if (name.isNotEmpty && phone.isNotEmpty) {
                    await ShopsService.registerShop(
                      name: name,
                      category: selectedCategory,
                      address: address.isNotEmpty ? address : 'Harur Town',
                      phone: phone,
                    );
                    widget.onCreated?.call();
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Shop registered! Promoted to Shop-Admin role.')),
                    );
                  }
                },
                child: const Text('Create Shop & Storefront', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
