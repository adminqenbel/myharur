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
      backgroundColor: const Color(0xFFF4F6F9), // Light background theme
      appBar: AppBar(
        title: const Text('Trending News', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF081C2D))),
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
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() => _fetchData()),
          )
        ],
      ),
      floatingActionButton: auth.isLoggedIn
          ? FloatingActionButton.extended(
              onPressed: _showSubmitNewsDialog,
              backgroundColor: const Color(0xFF081C2D),
              icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
              label: const Text('Post News', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                      _buildRateChip('Gold 22K', rates['gold_22k'], Icons.monetization_on_rounded),
                      const SizedBox(width: 8),
                      _buildRateChip('Gold 24K', rates['gold_24k'], Icons.monetization_on_rounded),
                      const SizedBox(width: 8),
                      _buildRateChip('Silver', rates['silver'], Icons.view_headline_rounded),
                      const SizedBox(width: 8),
                      _buildRateChip('Diamond', rates['diamond'], Icons.diamond_rounded),
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
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF3A86FF)));
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 64, color: Color(0xFFEF233C)),
                        const SizedBox(height: 16),
                        const Text('Failed to load news', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF081C2D))),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text('We could not reach the news server. Please try again.', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => setState(() => _fetchData()),
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                          label: const Text('Try Again', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3A86FF), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
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
                        Icon(Icons.article_rounded, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No news available yet.', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 16, bottom: 100), // padding for FAB/nav
                  itemCount: news.length,
                  itemBuilder: (context, index) {
                    final post = news[index];
                    return _buildModernNewsCard(post);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernNewsCard(Map<String, dynamic> post) {
    final bool hasImage = post['image_url'] != null && (post['image_url'] as String).isNotEmpty;
    final bool isVerified = post['source'] == 'Harur News Feed'; // Dummy logic for verified badge
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              if (post['url'] != null) {
                final Uri url = Uri.parse(post['url']);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasImage)
                  Stack(
                    children: [
                      Image.network(
                        post['image_url'],
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox(),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_rounded, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(post['location'] ?? 'Dharmapuri', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: const Color(0xFFF4F6F9), borderRadius: BorderRadius.circular(10)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(post['source'] ?? 'Local News', style: const TextStyle(color: Color(0xFF3A86FF), fontWeight: FontWeight.w700, fontSize: 12)),
                                if (isVerified) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified_rounded, color: Color(0xFF3A86FF), size: 14),
                                ]
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            post['created_at'] != null ? post['created_at'].toString().substring(0, 10) : '',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        post['title'] ?? 'News Update',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF081C2D), height: 1.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        post['content'] ?? '...',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 15, height: 1.5),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 20),
                      Divider(color: Colors.grey.shade200),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildInteractionButton(Icons.translate_rounded, 'Translate'),
                          _buildInteractionButton(Icons.mode_comment_outlined, 'Comment'),
                          _buildInteractionButton(Icons.bookmark_border_rounded, 'Save'),
                          _buildInteractionButton(Icons.share_rounded, 'Share'),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractionButton(IconData icon, String label) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
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
