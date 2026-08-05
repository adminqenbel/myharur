import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api_client.dart';
import '../providers/auth_provider.dart';
import '../l10n/translations.dart';
import '../theme.dart';
import '../utils/image_upload_helper.dart';
import '../widgets/design_system.dart';

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
      final r = await ApiClient.dio.get('/marketplace/');
      final List<dynamic> data = r.data;
      
      setState(() => _listings = data);
    } catch (_) {} finally {
      setState(() => _loadingListings = false);
    }
  }

  Future<void> _fetchJobs() async {
    setState(() => _loadingJobs = true);
    try {
      final r = await ApiClient.dio.get('/jobs/');
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

    showModalBottomSheet(useRootNavigator: true, 
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
              Text('Post a Listing', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              
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
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    image: imageUrl != null ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover) : null,
                  ),
                  child: isUploadingImage
                      ? Center(child: CircularProgressIndicator())
                      : imageUrl == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 40, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                                SizedBox(height: 8),
                                Text('Add Photo', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.bold)),
                              ],
                            )
                          : SizedBox(),
                ),
              ),
              SizedBox(height: 16),
              
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder())),
              SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 3),
              SizedBox(height: 12),
              TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price (₹) *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.currency_rupee)), keyboardType: TextInputType.number),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setMBS(() => selectedCategory = v!),
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCondition,
                decoration: const InputDecoration(labelText: 'Condition', border: OutlineInputBorder()),
                items: conditions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setMBS(() => selectedCondition = v!),
              ),
              SizedBox(height: 12),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Contact Phone', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: isSubmitting ? null : () async {
                  if (titleCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
                  setMBS(() => isSubmitting = true);
                  try {
                    await ApiClient.dio.post('/marketplace/', data: {
                      'title': titleCtrl.text,
                      'description': descCtrl.text,
                      'price': double.parse(priceCtrl.text),
                      'category': selectedCategory,
                      'condition': selectedCondition,
                      'contact_phone': phoneCtrl.text,
                      'type': 'sell',
                      'image_url': imageUrl,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _fetchListings();
                  } catch (e) {
                    if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    setMBS(() => isSubmitting = false);
                  }
                },
                style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 14)),
                child: isSubmitting ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.surface)) : Text('Post Listing', style: TextStyle(fontSize: 16)),
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

    showModalBottomSheet(useRootNavigator: true, 
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
              Text('Post a Job', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Job Title *', border: OutlineInputBorder())),
              SizedBox(height: 12),
              TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: 'Company / Name', border: OutlineInputBorder())),
              SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Job Description', border: OutlineInputBorder()), maxLines: 3),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Job Type', border: OutlineInputBorder()),
                items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setMBS(() => selectedType = v!),
              ),
              SizedBox(height: 12),
              TextField(controller: salaryCtrl, decoration: const InputDecoration(labelText: 'Salary Range (e.g. ₹8k-12k/month)', border: OutlineInputBorder())),
              SizedBox(height: 12),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Contact Phone *', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: isSubmitting ? null : () async {
                  if (titleCtrl.text.isEmpty) return;
                  setMBS(() => isSubmitting = true);
                  try {
                    await ApiClient.dio.post('/jobs/', data: {
                      'title': titleCtrl.text,
                      'company_name': companyCtrl.text,
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
                style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 14)),
                child: isSubmitting ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.surface)) : Text('Post Job', style: TextStyle(fontSize: 16)),
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
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.handshake_outlined, size: 18), text: 'Buy & Sell'),
              Tab(icon: Icon(Icons.work_outline, size: 18), text: 'Jobs'),
            ],
          ),
        ),
        floatingActionButton: auth.isLoggedIn
            ? Padding(
                padding: const EdgeInsets.only(bottom: 140),
                child: Builder(
                  builder: (ctx) {
                    final tab = DefaultTabController.of(ctx);
                    return FloatingActionButton.extended(
                      onPressed: () => tab.index == 0 ? _showCreateListingDialog() : _showCreateJobDialog(),
                      backgroundColor: AppTheme.accent,
                      foregroundColor: AppTheme.textPrimaryLight,
                      icon: Icon(Icons.add),
                      label: Text('Post', style: TextStyle(fontWeight: FontWeight.w700)),
                    );
                  },
                ),
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
    if (_loadingListings) return Center(child: CircularProgressIndicator());
    if (_listings.isEmpty) return _emptyState(Icons.handshake, 'No listings yet', 'Be the first to post!');
    return RefreshIndicator(
      onRefresh: _fetchListings,
      child: GridView.builder(
        padding: EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 180),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 12, mainAxisSpacing: 12),
        itemCount: _listings.length,
        itemBuilder: (ctx, i) {
          final item = _listings[i];
          return MHMarketplaceCard(
            item: item,
            onTap: () => _showListingDetail(item),
          );
        },
      ),
    );
  }

  void _showListingDetail(Map<String, dynamic> item) {
    showModalBottomSheet(useRootNavigator: true, 
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['title'] ?? '', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('₹${item['price']}', style: TextStyle(fontSize: 24, color: Colors.green, fontWeight: FontWeight.bold)),
            if (item['description'] != null) ...[SizedBox(height: 12), Text(item['description'])],
            SizedBox(height: 12),
            Row(children: [
              Chip(label: Text(item['category'] ?? '')),
              SizedBox(width: 8),
              Chip(label: Text(item['condition'] ?? '')),
            ]),
            SizedBox(height: 20),
            if (item['contact_phone'] != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.phone),
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
    if (_loadingJobs) return Center(child: CircularProgressIndicator());
    if (_jobs.isEmpty) return _emptyState(Icons.work, 'No jobs posted', 'Post a vacancy above!');
    return RefreshIndicator(
      onRefresh: _fetchJobs,
      child: ListView.builder(
        padding: EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 180),
        itemCount: _jobs.length,
        itemBuilder: (ctx, i) {
          final job = _jobs[i];
          return Card(
            margin: EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.work, color: Theme.of(context).colorScheme.surface)),
              title: Text(job['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (job['company_name'] != null) Text(job['company_name'], style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                  if (job['salary_range'] != null) Text(job['salary_range'], style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  Container(margin: EdgeInsets.only(top: 4), padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)), child: Text(job['job_type'] ?? '', style: TextStyle(color: Colors.blue, fontSize: 11))),
                ],
              ),
              trailing: job['contact_phone'] != null
                  ? IconButton(
                      icon: Icon(Icons.phone, color: Colors.green),
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
      Icon(icon, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
      SizedBox(height: 16),
      Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
      Text(sub, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
    ]));
  }
}
