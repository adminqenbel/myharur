import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api_client.dart';
import '../providers/auth_provider.dart';
import '../l10n/translations.dart';
import '../theme.dart';
import '../utils/image_upload_helper.dart';

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  List<dynamic> _listings = [];
  List<dynamic> _jobs = [];
  bool _loadingListings = true;
  bool _loadingJobs = true;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    _fetchListings();
    _fetchJobs();
  }

  Future<void> _fetchListings() async {
    setState(() => _loadingListings = true);
    try {
      final r = await ApiClient.dio.get('/community/listings');
      setState(() => _listings = r.data);
    } catch (_) {} finally {
      setState(() => _loadingListings = false);
    }
  }

  Future<void> _fetchJobs() async {
    setState(() => _loadingJobs = true);
    try {
      final r = await ApiClient.dio.get('/community/jobs');
      setState(() => _jobs = r.data);
    } catch (_) {} finally {
      setState(() => _loadingJobs = false);
    }
  }

  void _showCreateListingDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String selectedCategory = 'Electronics';
    String selectedCondition = 'Used';
    String? imageUrl;
    bool isUploadingImage = false;
    bool isSubmitting = false;
    final categories = ['Electronics', 'Furniture', 'Bikes', 'Vehicles', 'Clothing', 'Books', 'Pets', 'Other'];
    final conditions = ['New', 'Like New', 'Used'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMBS) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          builder: (_, sc) => Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
            child: ListView(controller: sc, children: [
              const Text('Post a Listing', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Image Upload Section
              GestureDetector(
                onTap: () async {
                  if (isUploadingImage) return;
                  setMBS(() => isUploadingImage = true);
                  final url = await ImageUploadHelper.pickAndUpload();
                  setMBS(() {
                    if (url != null) imageUrl = url;
                    isUploadingImage = false;
                  });
                },
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    image: imageUrl != null ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover) : null,
                  ),
                  child: isUploadingImage
                      ? const Center(child: CircularProgressIndicator())
                      : imageUrl == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Add Photo', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                              ],
                            )
                          : const SizedBox(),
                ),
              ),
              const SizedBox(height: 16),
              
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 3),
              const SizedBox(height: 12),
              TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price (₹) *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.currency_rupee)), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setMBS(() => selectedCategory = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCondition,
                decoration: const InputDecoration(labelText: 'Condition', border: OutlineInputBorder()),
                items: conditions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setMBS(() => selectedCondition = v!),
              ),
              const SizedBox(height: 12),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Contact Phone', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isSubmitting ? null : () async {
                  if (titleCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
                  setMBS(() => isSubmitting = true);
                  try {
                    await ApiClient.dio.post('/community/listings', data: {
                      'title': titleCtrl.text,
                      'description': descCtrl.text,
                      'price': double.parse(priceCtrl.text),
                      'category': selectedCategory,
                      'condition': selectedCondition,
                      'contact_phone': phoneCtrl.text,
                      'image_urls': imageUrl != null ? [imageUrl] : [],
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _fetchListings();
                  } catch (e) {
                    if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    setMBS(() => isSubmitting = false);
                  }
                },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: isSubmitting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Post Listing', style: TextStyle(fontSize: 16)),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _showCreateJobDialog() {
    final titleCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final salaryCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String selectedType = 'Full-time';
    bool isSubmitting = false;
    final types = ['Full-time', 'Part-time', 'Contract', 'Freelance', 'Internship'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMBS) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          builder: (_, sc) => Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
            child: ListView(controller: sc, children: [
              const Text('Post a Job', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Job Title *', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: 'Company / Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Job Description', border: OutlineInputBorder()), maxLines: 3),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Job Type', border: OutlineInputBorder()),
                items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setMBS(() => selectedType = v!),
              ),
              const SizedBox(height: 12),
              TextField(controller: salaryCtrl, decoration: const InputDecoration(labelText: 'Salary Range (e.g. ₹8k-12k/month)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Contact Phone *', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isSubmitting ? null : () async {
                  if (titleCtrl.text.isEmpty) return;
                  setMBS(() => isSubmitting = true);
                  try {
                    await ApiClient.dio.post('/community/jobs', data: {
                      'title': titleCtrl.text,
                      'company': companyCtrl.text,
                      'description': descCtrl.text,
                      'job_type': selectedType,
                      'salary_range': salaryCtrl.text,
                      'contact_phone': phoneCtrl.text,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _fetchJobs();
                  } catch (e) {
                    if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    setMBS(() => isSubmitting = false);
                  }
                },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: isSubmitting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Post Job', style: TextStyle(fontSize: 16)),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(l(ref, 'Marketplace')),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.handshake_outlined, size: 18), text: 'Buy & Sell'),
              Tab(icon: Icon(Icons.work_outline, size: 18), text: 'Jobs'),
            ],
          ),
        ),
        floatingActionButton: auth.isLoggedIn
            ? Builder(
                builder: (ctx) {
                  final tab = DefaultTabController.of(ctx);
                  return FloatingActionButton.extended(
                    onPressed: () => tab.index == 0 ? _showCreateListingDialog() : _showCreateJobDialog(),
                    backgroundColor: AppTheme.primaryYellow,
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.add),
                    label: const Text('Post', style: TextStyle(fontWeight: FontWeight.w700)),
                  );
                },
              )
            : null,
        body: TabBarView(
          children: [
            _buildListings(),
            _buildJobs(),
          ],
        ),
      ),
    );
  }

  Widget _buildListings() {
    if (_loadingListings) return const Center(child: CircularProgressIndicator());
    if (_listings.isEmpty) return _emptyState(Icons.handshake, 'No listings yet', 'Be the first to post!');
    return RefreshIndicator(
      onRefresh: _fetchListings,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 12, mainAxisSpacing: 12),
        itemCount: _listings.length,
        itemBuilder: (ctx, i) {
          final item = _listings[i];
          final isSold = item['is_sold'] == true;
          final List? imageUrls = item['image_urls'] as List?;
          final String? imageUrl = (imageUrls != null && imageUrls.isNotEmpty) ? imageUrls[0] : null;

          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _showListingDetail(item),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 110,
                    width: double.infinity,
                    color: Colors.blue.shade50,
                    child: imageUrl != null
                        ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Icon(Icons.image, size: 40, color: Colors.blue.shade200)))
                        : Center(child: Icon(Icons.image, size: 40, color: Colors.blue.shade200)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isSold) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)), child: const Text('SOLD', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                        Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('₹${item['price']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(item['condition'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showListingDetail(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['title'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('₹${item['price']}', style: const TextStyle(fontSize: 24, color: Colors.green, fontWeight: FontWeight.bold)),
            if (item['description'] != null) ...[const SizedBox(height: 12), Text(item['description'])],
            const SizedBox(height: 12),
            Row(children: [
              Chip(label: Text(item['category'] ?? '')),
              const SizedBox(width: 8),
              Chip(label: Text(item['condition'] ?? '')),
            ]),
            const SizedBox(height: 20),
            if (item['contact_phone'] != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.phone),
                  label: Text('Call ${item['contact_phone']}'),
                  onPressed: () async {
                    final url = Uri.parse('tel:${item['contact_phone']}');
                    if (await canLaunchUrl(url)) await launchUrl(url);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobs() {
    if (_loadingJobs) return const Center(child: CircularProgressIndicator());
    if (_jobs.isEmpty) return _emptyState(Icons.work, 'No jobs posted', 'Post a vacancy above!');
    return RefreshIndicator(
      onRefresh: _fetchJobs,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _jobs.length,
        itemBuilder: (ctx, i) {
          final job = _jobs[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.work, color: Colors.white)),
              title: Text(job['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (job['company'] != null) Text(job['company'], style: const TextStyle(color: Colors.grey)),
                  if (job['salary_range'] != null) Text(job['salary_range'], style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)), child: Text(job['job_type'] ?? '', style: TextStyle(color: Colors.blue.shade900, fontSize: 11))),
                ],
              ),
              trailing: job['contact_phone'] != null
                  ? IconButton(
                      icon: const Icon(Icons.phone, color: Colors.green),
                      onPressed: () async {
                        final url = Uri.parse('tel:${job['contact_phone']}');
                        if (await canLaunchUrl(url)) await launchUrl(url);
                      },
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String sub) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
      Text(sub, style: const TextStyle(color: Colors.grey)),
    ]));
  }
}
