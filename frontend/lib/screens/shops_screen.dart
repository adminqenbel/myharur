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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Light background theme
      appBar: AppBar(
        title: Text('Local Businesses', style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Search coming soon!')));
            },
          ),
          IconButton(
            icon: Icon(Icons.filter_list_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Filters coming soon!')));
            },
          )
        ],
      ),
      body: Column(
        children: [
          // ── Category Chips ───────────────────────────────────────────
          Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), width: 1)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildCategoryChip('All Categories', true),
                  SizedBox(width: 8),
                  _buildCategoryChip('Food & Dining', false),
                  SizedBox(width: 8),
                  _buildCategoryChip('Groceries', false),
                  SizedBox(width: 8),
                  _buildCategoryChip('Services', false),
                  SizedBox(width: 8),
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
                  return Center(child: CircularProgressIndicator(color: AppTheme.info));
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.store_mall_directory_rounded, size: 64, color: AppTheme.danger),
                        SizedBox(height: 16),
                        Text('Failed to load shops', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                        SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text('We could not reach the directory server. Please try again.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 14)),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => setState(() => _shopsFuture = _fetchShops()),
                          icon: Icon(Icons.refresh_rounded, color: Theme.of(context).colorScheme.surface),
                          label: Text('Try Again', style: TextStyle(color: Theme.of(context).colorScheme.surface)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent, 
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14), 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final shops = snapshot.data ?? [];
                if (shops.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.storefront_rounded, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                        SizedBox(height: 16),
                        Text('No businesses listed yet.', style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.only(top: 16, bottom: 100), // padding for FAB/nav
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
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: isSelected ? null : Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildModernShopCard(Map<String, dynamic> shop) {
    final bool isOpen = (shop['is_open'] as bool?) ?? true; // Dummy logic
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shop details coming soon!')));
          }, // Navigate to shop details
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                      ),
                      child: Center(child: Icon(Icons.storefront_rounded, size: 36, color: AppTheme.info)),
                    ),
                    SizedBox(width: 16),
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
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Theme.of(context).colorScheme.onSurface),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isOpen ? AppTheme.success.withOpacity(0.1) : AppTheme.danger.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isOpen ? 'OPEN' : 'CLOSED',
                                  style: TextStyle(
                                    color: isOpen ? AppTheme.success : AppTheme.danger,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            ],
                          ),
                          SizedBox(height: 6),
                          Text(
                            shop['description'] ?? 'Supporting local economy in Harur.',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13, height: 1.4),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.star_rounded, color: AppTheme.accent, size: 16),
                              SizedBox(width: 4),
                              Text('4.8', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              SizedBox(width: 16),
                              Icon(Icons.location_on_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), size: 14),
                              SizedBox(width: 4),
                              Text('0.5 km away', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12)),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Divider(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), height: 1),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(Icons.call_rounded, 'Call', AppTheme.info),
                    _buildActionButton(Icons.directions_rounded, 'Directions', AppTheme.success),
                    _buildActionButton(Icons.chat_bubble_rounded, 'WhatsApp', AppTheme.success),
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
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label coming soon!')));
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
