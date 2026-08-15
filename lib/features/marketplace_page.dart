import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/supabase_service.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  int selectedCategory = 0;
  final categories = ['All', 'Farm & Tools', 'Vehicles', 'Electronics', 'Furniture', 'Books'];
  List<Map<String, dynamic>> items = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings() async {
    setState(() => isLoading = true);
    final category = categories[selectedCategory];
    final data = await MarketplaceService.fetchListings(category: category);
    if (mounted) {
      setState(() {
        items = data;
        isLoading = false;
      });
    }
  }

  void _openPostItemSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _PostMarketplaceItemSheet(onCreated: _loadListings),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = items;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Harur Marketplace',
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
            // Category horizontal tabs
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

            // Item Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final item = filtered[i];
                  return InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => _showItemDetailModal(context, item),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFDCE5E1)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x080F2922), blurRadius: 12, offset: Offset(0, 4))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Thumbnail header
                          Container(
                            height: 110,
                            decoration: BoxDecoration(
                              color: (item['color'] as Color).withValues(alpha: .1),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/icons/bag.svg',
                                width: 38,
                                height: 38,
                                colorFilter: ColorFilter.mode(item['color'] as Color, BlendMode.srcIn),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2F6F5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item['condition'],
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF697570)),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item['title'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, height: 1.2),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item['price'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF007F63),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF697570)),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Text(
                                        item['location'],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF697570)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
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
        icon: const Icon(Icons.add_rounded),
        label: const Text('Post Item', style: TextStyle(fontWeight: FontWeight.w800)),
        onPressed: _openPostItemSheet,
      ),
    );
  }

  void _showItemDetailModal(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
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
            const SizedBox(height: 20),
            Text(
              item['price'],
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF007F63)),
            ),
            const SizedBox(height: 6),
            Text(
              item['title'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.2),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F6F5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFF007F63),
                    child: Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['seller'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        Text('Listed in ${item['location']} · ${item['time']}', style: const TextStyle(fontSize: 12, color: Color(0xFF697570))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007F63),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.call_rounded, size: 20),
                    label: const Text('Call Seller', style: TextStyle(fontWeight: FontWeight.w800)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Calling ${item['seller']} (${item['phone']})...')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF15211F),
                      side: const BorderSide(color: Color(0xFFDCE5E1)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                    label: const Text('Town Chat', style: TextStyle(fontWeight: FontWeight.w800)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _PostMarketplaceItemSheet extends StatefulWidget {
  final VoidCallback? onCreated;
  const _PostMarketplaceItemSheet({this.onCreated});

  @override
  State<_PostMarketplaceItemSheet> createState() => _PostMarketplaceItemSheetState();
}

class _PostMarketplaceItemSheetState extends State<_PostMarketplaceItemSheet> {
  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String selectedCondition = 'Like New';
  String selectedCategory = 'Farm & Tools';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
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
                decoration: BoxDecoration(color: const Color(0xFFDCE5E1), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'List Item for Sale',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF15211F)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Sell peer-to-peer to verified neighbours across Harur.',
              style: TextStyle(fontSize: 12, color: Color(0xFF697570)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: 'Item title',
                filled: true,
                fillColor: const Color(0xFFF2F6F5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Price (₹)',
                filled: true,
                fillColor: const Color(0xFFF2F6F5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Details & Condition notes',
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
                  final title = _titleCtrl.text.trim();
                  final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
                  final desc = _descCtrl.text.trim();
                  if (title.isNotEmpty && price > 0) {
                    await MarketplaceService.createListing(
                      title: title,
                      description: desc,
                      price: price,
                      condition: selectedCondition,
                      category: selectedCategory,
                    );
                    widget.onCreated?.call();
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Item published to Harur Marketplace!')),
                    );
                  }
                },
                child: const Text('Publish Item', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
