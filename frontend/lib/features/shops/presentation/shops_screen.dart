import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';

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
      appBar: AppBar(
        title: const Text('MyHarur Shops'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Search coming soon!')))),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _shopsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading shops: ${snapshot.error}'));
          }
          
          final shops = snapshot.data ?? [];
          if (shops.isEmpty) {
            return const Center(child: Text('No shops found in MyHarur.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: shops.length,
            itemBuilder: (context, index) {
              final shop = shops[index];
              return Card(
                elevation: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        color: Colors.grey[300],
                        child: shop['logo_url'] != null 
                            ? Image.network(shop['logo_url'], fit: BoxFit.cover)
                            : const Icon(Icons.store, size: 50, color: Colors.grey),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(shop['name'] ?? 'Unknown Shop', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const Text('Category', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          );
        }
      ),
    );
  }
}
