import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ShopsPage extends StatefulWidget {
  const ShopsPage({super.key});

  @override
  State<ShopsPage> createState() => _ShopsPageState();
}

class _ShopsPageState extends State<ShopsPage> {
  int selectedCategory = 0;
  final categories = ['All', 'Groceries & Agro', 'Electronics', 'Textiles & Silk', 'Sweets & Bakery'];

  final List<Map<String, dynamic>> shops = [
    {
      'name': 'Sri Lakshmi Agro & Seed Agency',
      'category': 'Groceries & Agro',
      'owner': 'K. Ramanathan (Shop Admin)',
      'address': 'No. 14, Bazaar Street, Harur',
      'phone': '9842011445',
      'rating': '4.9 (128 reviews)',
      'productsCount': 34,
      'isVerified': true,
      'color': Color(0xFF007F63),
    },
    {
      'name': 'Dharmapuri Handloom Silk Sarees',
      'category': 'Textiles & Silk',
      'owner': 'M. Sundaram (Shop Admin)',
      'address': 'Opposite Old Bus Stand, Harur',
      'phone': '9443277889',
      'rating': '4.8 (94 reviews)',
      'productsCount': 52,
      'isVerified': true,
      'color': Color(0xFFE44545),
    },
    {
      'name': 'Vasantham Digital & Mobile Care',
      'category': 'Electronics',
      'owner': 'R. Vijay (Shop Admin)',
      'address': 'Kamarajar Salai, Harur',
      'phone': '9789066778',
      'rating': '4.7 (76 reviews)',
      'productsCount': 28,
      'isVerified': true,
      'color': Color(0xFF267AF4),
    },
  ];

  void _openRegisterShopSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => const _RegisterShopSheet(),
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
                                label: const Text('View Storefront', style: TextStyle(fontWeight: FontWeight.w800)),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Opening ${shop['name']} catalog...')),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton.outlined(
                              icon: const Icon(Icons.call_rounded, color: Color(0xFF15211F)),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Calling ${shop['phone']}...')),
                                );
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
  const _RegisterShopSheet();

  @override
  State<_RegisterShopSheet> createState() => _RegisterShopSheetState();
}

class _RegisterShopSheetState extends State<_RegisterShopSheet> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
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
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Shop registered! Promoted to Shop-Admin role.')),
                  );
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
