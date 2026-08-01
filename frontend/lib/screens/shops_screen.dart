import 'package:flutter/material.dart';
import '../api_client.dart';
import '../theme.dart';

class ShopsScreen extends StatefulWidget {
  const ShopsScreen({super.key});

  @override
  State<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends State<ShopsScreen> {
  late Future<List<dynamic>> _shopsFuture;

  @override
  void initState() {
    super.initState();
    _shopsFuture = _fetchShops();
  }

  Future<List<dynamic>> _fetchShops() async {
    final response = await ApiClient.dio.get('/shops/');
    return response.data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9), // Light background theme
      appBar: AppBar(
        title: const Text('Local Businesses', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF081C2D))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF081C2D)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {},
          )
        ],
      ),
      body: Column(
        children: [
          // ── Category Chips ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildCategoryChip('All Categories', true),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Food & Dining', false),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Groceries', false),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Services', false),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Electronics', false),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _shopsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF3A86FF)));
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.store_mall_directory_rounded, size: 64, color: Color(0xFFEF233C)),
                        const SizedBox(height: 16),
                        const Text('Failed to load shops', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF081C2D))),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text('We could not reach the directory server. Please try again.', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => setState(() => _shopsFuture = _fetchShops()),
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                          label: const Text('Try Again', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent, 
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final shops = snapshot.data ?? [];
                if (shops.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.storefront_rounded, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No businesses listed yet.', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 16, bottom: 100), // padding for FAB/nav
                  itemCount: shops.length,
                  itemBuilder: (context, index) {
                    final shop = shops[index];
                    return _buildModernShopCard(shop);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF081C2D) : const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(20),
        border: isSelected ? null : Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF64748B),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildModernShopCard(Map<String, dynamic> shop) {
    final bool isOpen = (shop['is_open'] as bool?) ?? true; // Dummy logic
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {}, // Navigate to shop details
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Center(child: Icon(Icons.storefront_rounded, size: 36, color: Color(0xFF3A86FF))),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  shop['name'] ?? 'Local Business',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF081C2D)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isOpen ? const Color(0xFF06D6A0).withOpacity(0.1) : const Color(0xFFEF233C).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isOpen ? 'OPEN' : 'CLOSED',
                                  style: TextStyle(
                                    color: isOpen ? const Color(0xFF06D6A0) : const Color(0xFFEF233C),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            shop['description'] ?? 'Supporting local economy in Harur.',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFFFB703), size: 16),
                              const SizedBox(width: 4),
                              const Text('4.8', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(width: 16),
                              const Icon(Icons.location_on_rounded, color: Color(0xFF64748B), size: 14),
                              const SizedBox(width: 4),
                              const Text('0.5 km away', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade100, height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(Icons.call_rounded, 'Call', const Color(0xFF3A86FF)),
                    _buildActionButton(Icons.directions_rounded, 'Directions', const Color(0xFF06D6A0)),
                    _buildActionButton(Icons.chat_bubble_rounded, 'WhatsApp', const Color(0xFF06D6A0)),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
