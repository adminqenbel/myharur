import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../utils/image_upload_helper.dart';

class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen> {
  late Future<List<dynamic>> _newsFuture;
  late Future<Map<String, dynamic>> _ratesFuture;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    _newsFuture = _fetchNews();
    _ratesFuture = _fetchRates();
  }

  Future<List<dynamic>> _fetchNews() async {
    final response = await ApiClient.dio.get('/news/');
    return response.data;
  }

  Future<Map<String, dynamic>> _fetchRates() async {
    try {
      final response = await ApiClient.dio.get('/rates/');
      return response.data;
    } catch (e) {
      return {};
    }
  }

  void _showSubmitNewsDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? imageUrl;
    bool isUploadingImage = false;

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
              const Text('Submit News', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Share local news or updates. It will be public after moderation.', style: TextStyle(color: Colors.grey)),
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
                  height: 140,
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
              
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'News Headline *', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Details / Content *', border: OutlineInputBorder()), maxLines: 5),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (titleCtrl.text.isEmpty || descCtrl.text.isEmpty) return;
                  try {
                    await ApiClient.dio.post('/news/', data: {
                      'title': titleCtrl.text,
                      'description': descCtrl.text,
                      'image_url': imageUrl,
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('News submitted for moderation.')));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Submit for Review', style: TextStyle(fontSize: 16)),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyHarur News'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _newsFuture = _fetchNews();
              });
            },
          )
        ],
      ),
      floatingActionButton: auth.isLoggedIn
          ? FloatingActionButton.extended(
              onPressed: _showSubmitNewsDialog,
              icon: const Icon(Icons.add),
              label: const Text('Submit News'),
            )
          : null,
      body: Column(
        children: [
          // Rates Widget
          FutureBuilder<Map<String, dynamic>>(
            future: _ratesFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
              final rates = snapshot.data!;
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: Colors.amber.shade50,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      _buildRateChip('Gold 22K', rates['gold_22k'], Icons.monetization_on),
                      const SizedBox(width: 8),
                      _buildRateChip('Gold 24K', rates['gold_24k'], Icons.monetization_on),
                      const SizedBox(width: 8),
                      _buildRateChip('Silver', rates['silver'], Icons.view_headline),
                      const SizedBox(width: 8),
                      _buildRateChip('Diamond', rates['diamond'], Icons.diamond),
                    ],
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _newsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text('Failed to load news', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(snapshot.error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() => _fetchData()),
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  );
                }

                final news = snapshot.data ?? [];
                if (news.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.article, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No news available.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: news.length,
                  itemBuilder: (context, index) {
                    final post = news[index];
                    return GestureDetector(
                      onTap: () async {
                        if (post['url'] != null) {
                          final Uri url = Uri.parse(post['url']);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        }
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: post['url'] != null ? 3 : 1,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (post['image_url'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      post['image_url'],
                                      width: double.infinity,
                                      height: 180,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const SizedBox(),
                                    ),
                                  ),
                                ),
                              Text(post['title'] ?? 'News Update', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(post['content'] ?? '...', style: Theme.of(context).textTheme.bodyMedium),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(post['source'] ?? 'Local News', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                  Text(post['created_at'] != null ? post['created_at'].toString().substring(0, 10) : '', style: const TextStyle(color: Colors.grey)),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateChip(String label, String? value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.amber.shade800),
          const SizedBox(width: 6),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Text(value ?? '...', style: const TextStyle(color: Colors.black87, fontSize: 12)),
        ],
      ),
    );
  }
}
