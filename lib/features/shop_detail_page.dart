import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/glass_components.dart';

class ShopDetailPage extends StatefulWidget {
  final Map<String, dynamic> shop;
  const ShopDetailPage({super.key, required this.shop});

  @override
  State<ShopDetailPage> createState() => _ShopDetailPageState();
}

class _ShopDetailPageState extends State<ShopDetailPage> {
  String searchQuery = '';
  late List<Map<String, dynamic>> products;

  @override
  void initState() {
    super.initState();
    // Default catalog based on shop category or populated items
    final category = widget.shop['category'] ?? 'Groceries & Agro';

    products = [
      {
        'name': 'Premium Ponni Rice (25kg Bag)',
        'price': '₹1,450',
        'unit': 'Bag',
        'inStock': true,
        'tag': 'Best Seller',
        'icon': Icons.grain_rounded,
      },
      {
        'name': 'Cold Pressed Gingelly Oil (1L)',
        'price': '₹240',
        'unit': 'Bottle',
        'inStock': true,
        'tag': 'Organic',
        'icon': Icons.opacity_rounded,
      },
      {
        'name': 'Country Jaggery Blocks (1kg)',
        'price': '₹65',
        'unit': 'Pack',
        'inStock': true,
        'tag': 'Harur Local',
        'icon': Icons.bakery_dining_rounded,
      },
      {
        'name': 'Turmeric Powder (Pure Agmark 500g)',
        'price': '₹110',
        'unit': 'Pack',
        'inStock': true,
        'tag': 'Fresh Harvest',
        'icon': Icons.eco_rounded,
      },
      {
        'name': 'Farm Fresh Red Chillies (1kg)',
        'price': '₹180',
        'unit': 'kg',
        'inStock': false,
        'tag': 'Seasonal',
        'icon': Icons.local_florist_rounded,
      },
    ];

    if (category.toString().contains('Electronics')) {
      products = [
        {
          'name': 'Submersible Pump Starter 5HP',
          'price': '₹4,850',
          'unit': 'Unit',
          'inStock': true,
          'tag': 'Warranty 2Y',
          'icon': Icons.electric_bolt_rounded,
        },
        {
          'name': 'Heavy Duty Agricultural Copper Wire',
          'price': '₹85 / m',
          'unit': 'Meter',
          'inStock': true,
          'tag': 'ISI Certified',
          'icon': Icons.cable_rounded,
        },
        {
          'name': 'Solar LED Streetlight Panel 50W',
          'price': '₹2,200',
          'unit': 'Set',
          'inStock': true,
          'tag': 'Auto Sensor',
          'icon': Icons.solar_power_rounded,
        },
      ];
    } else if (category.toString().contains('Textiles')) {
      products = [
        {
          'name': 'Traditional Dharmapuri Silk Saree',
          'price': '₹3,400',
          'unit': 'Piece',
          'inStock': true,
          'tag': 'Pure Zari',
          'icon': Icons.checkroom_rounded,
        },
        {
          'name': 'Pure Cotton Dhoti & Angavastram',
          'price': '₹550',
          'unit': 'Set',
          'inStock': true,
          'tag': 'Temple Special',
          'icon': Icons.dry_cleaning_rounded,
        },
      ];
    }
  }

  Future<void> _launch(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $e')),
        );
      }
    }
  }

  void _openAddProductSheet() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'Pack');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE5E5EA), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Add Catalog Product',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E)),
              ),
              const SizedBox(height: 4),
              const Text('Add product to your digital storefront for Harur shoppers.', style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Product Name',
                  filled: true,
                  fillColor: const Color(0xFFF2F2F7),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                decoration: InputDecoration(
                  labelText: 'Price (e.g. ₹250 or ₹50/kg)',
                  filled: true,
                  fillColor: const Color(0xFFF2F2F7),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unitCtrl,
                decoration: InputDecoration(
                  labelText: 'Unit / Packaging (kg, piece, liter, box)',
                  filled: true,
                  fillColor: const Color(0xFFF2F2F7),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final price = priceCtrl.text.trim();
                    if (name.isNotEmpty && price.isNotEmpty) {
                      setState(() {
                        products.insert(0, {
                          'name': name,
                          'price': price.startsWith('₹') ? price : '₹$price',
                          'unit': unitCtrl.text.trim().isNotEmpty ? unitCtrl.text.trim() : 'Unit',
                          'inStock': true,
                          'tag': 'New Arrival',
                          'icon': Icons.shopping_bag_rounded,
                        });
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(backgroundColor: Color(0xFF007AFF), content: Text('✓ Product added to store catalog!')),
                      );
                    }
                  },
                  child: const Text('Add to Storefront', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopName = widget.shop['name'] ?? 'Local Store';
    final address = widget.shop['address'] ?? 'Harur Bazaar Street';
    final phone = widget.shop['phone'] ?? '9842011000';
    final rating = widget.shop['rating'] ?? '4.8 (42)';
    final category = widget.shop['category'] ?? 'Groceries & Agro';

    final filtered = searchQuery.isEmpty
        ? products
        : products.where((p) => p['name'].toString().toLowerCase().contains(searchQuery.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          shopName,
          style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E), fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1C1C1E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF007AFF)),
            tooltip: 'Add Product Item',
            onPressed: _openAddProductSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store Header Glass Card
              GlassCard(
                level: GlassLevel.level2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF007AFF).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.storefront_rounded, color: Color(0xFF007AFF), size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      shopName,
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1C1C1E)),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.verified_rounded, color: Color(0xFF007AFF), size: 18),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(category, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93), fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF5FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, color: Color(0xFF007AFF), size: 7),
                              SizedBox(width: 5),
                              Text('OPEN NOW · Closes 9:00 PM', style: TextStyle(color: Color(0xFF007AFF), fontSize: 10, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                        const SizedBox(width: 4),
                        Text(rating, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1C1C1E))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: Color(0xFF8E8E93), size: 15),
                        const SizedBox(width: 4),
                        Expanded(child: Text(address, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)))),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Contact & Action Bar (WhatsApp, Call, Directions)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.chat_rounded, size: 18),
                      label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                      onPressed: () => _launch('https://wa.me/91$phone?text=Hello+${Uri.encodeComponent(shopName)},+inquiring+about+products+from+MyHarur+app.'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.call_rounded, size: 18),
                      label: const Text('Call Shop', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                      onPressed: () => _launch('tel:$phone'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF2F2F7),
                      foregroundColor: const Color(0xFF267AF4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.directions_rounded, size: 22),
                    tooltip: 'Google Maps Directions',
                    onPressed: () => _launch('https://www.google.com/maps/search/?api=1&query=Harur+${Uri.encodeComponent("$shopName $address")}'),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Store Offer Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF007AFF).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.local_offer_rounded, color: Color(0xFF007AFF), size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Harur Resident Special Offer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                          SizedBox(height: 2),
                          Text('Show your MMID Digital Pass for 5% instant discount on bulk billing.', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Product Catalog Header & Search
              Row(
                children: [
                  const Text('PRODUCTS & ITEMS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF8E8E93), letterSpacing: 1.1)),
                  const Spacer(),
                  Text('${filtered.length} Items Available', style: const TextStyle(fontSize: 11, color: Color(0xFF007AFF), fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                onChanged: (val) => setState(() => searchQuery = val.trim()),
                decoration: InputDecoration(
                  hintText: 'Search items in this shop...',
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF007AFF)),
                  filled: true,
                  fillColor: const Color(0xFFF2F2F7),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),

              // Product Items List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final p = filtered[i];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE5E5EA)),
                      boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 3))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF5FF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(p['icon'] as IconData? ?? Icons.inventory_2_rounded, color: const Color(0xFF007AFF), size: 22),
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
                                      p['name'] as String,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1C1C1E)),
                                    ),
                                  ),
                                  if (p['tag'] != null) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        p['tag'] as String,
                                        style: const TextStyle(color: Color(0xFF007AFF), fontSize: 9, fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${p['price']} · Per ${p['unit']}',
                                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF007AFF), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          style: IconButton.styleFrom(backgroundColor: const Color(0xFFEBF5FF)),
                          icon: const Icon(Icons.add_shopping_cart_rounded, color: Color(0xFF007AFF), size: 18),
                          tooltip: 'Order on WhatsApp',
                          onPressed: () {
                            _launch('https://wa.me/91$phone?text=Hi+${Uri.encodeComponent(shopName)},+I+would+like+to+buy+${Uri.encodeComponent(p['name'] as String)}+priced+at+${Uri.encodeComponent(p['price'] as String)}.');
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
