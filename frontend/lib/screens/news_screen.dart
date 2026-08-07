import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../utils/image_upload_helper.dart';
import '../theme.dart';
import '../widgets/design_system.dart';

class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen> {
  late Future<List<dynamic>> _newsFuture;
  late Future<Map<String, dynamic>> _ratesFuture;
  Timer? _newsTimer;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _newsTimer = Timer.periodic(const Duration(hours: 2), (timer) {
      if (mounted) setState(() => _fetchData());
    });
  }

  @override
  void dispose() {
    _newsTimer?.cancel();
    super.dispose();
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
              Text('Submit News', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Share local news or updates. It will be public after moderation.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
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
                  height: 140,
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
              
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'News Headline *', border: OutlineInputBorder())),
              SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Details / Content *', border: OutlineInputBorder()), maxLines: 5),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill out all required fields.'), backgroundColor: Colors.red));
                    return;
                  }
                  try {
                    await ApiClient.dio.post('/news/', data: {
                      'title': titleCtrl.text,
                      'description': descCtrl.text,
                      'image_url': imageUrl,
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('News submitted for moderation.')));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 14)),
                child: Text('Submit for Review', style: TextStyle(fontSize: 16)),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Light background theme
      appBar: AppBar(
        title: Text('Trending News', style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded),
            onPressed: () => setState(() => _fetchData()),
          )
        ],
      ),
      floatingActionButton: auth.isLoggedIn
          ? Padding(
              padding: EdgeInsets.only(bottom: 100),
              child: FloatingActionButton.extended(
                onPressed: _showSubmitNewsDialog,
                backgroundColor: AppTheme.accent,
                icon: Icon(Icons.add_circle_outline_rounded, color: AppTheme.textPrimaryLight),
                label: Text('Post News', style: TextStyle(color: AppTheme.textPrimaryLight, fontWeight: FontWeight.bold)),
              ),
            )
          : null,
      body: Column(
        children: [
          // Rates Widget
          FutureBuilder<Map<String, dynamic>>(
            future: _ratesFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) return SizedBox.shrink();
              final rates = snapshot.data!;
              return Container(
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
                      _buildRateChip('Gold 22K', rates['gold_22k'], Icons.monetization_on_rounded),
                      SizedBox(width: 8),
                      _buildRateChip('Gold 24K', rates['gold_24k'], Icons.monetization_on_rounded),
                      SizedBox(width: 8),
                      _buildRateChip('Silver', rates['silver'], Icons.view_headline_rounded),
                      SizedBox(width: 8),
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
                  return Center(child: CircularProgressIndicator(color: AppTheme.accent));
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off_rounded, size: 64, color: AppTheme.danger),
                        SizedBox(height: 16),
                        Text('Failed to load news', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                        SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text('We could not reach the news server. Please try again.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 14)),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => setState(() => _fetchData()),
                          icon: Icon(Icons.refresh_rounded, color: AppTheme.textPrimaryLight),
                          label: Text('Try Again', style: TextStyle(color: AppTheme.textPrimaryLight, fontWeight: FontWeight.bold)),
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

                final news = snapshot.data ?? [];
                if (news.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.article_rounded, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                        SizedBox(height: 16),
                        Text('No news available yet.', style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.only(top: 16, bottom: 100), // padding for FAB/nav
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
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
                      MHImage(
                        url: post['image_url'],
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on_rounded, color: Theme.of(context).colorScheme.surface, size: 14),
                              SizedBox(width: 4),
                              Text(post['location'] ?? 'Dharmapuri', style: TextStyle(color: Theme.of(context).colorScheme.surface, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(10)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(post['source'] ?? 'Local News', style: TextStyle(color: AppTheme.info, fontWeight: FontWeight.w700, fontSize: 12)),
                                if (isVerified) ...[
                                  SizedBox(width: 4),
                                  Icon(Icons.verified_rounded, color: AppTheme.info, size: 14),
                                ]
                              ],
                            ),
                          ),
                          Spacer(),
                          Text(
                            post['created_at'] != null ? post['created_at'].toString().substring(0, 10) : '',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      SizedBox(height: 14),
                      Text(
                        post['title'] ?? 'News Update',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Theme.of(context).colorScheme.onSurface, height: 1.3),
                      ),
                      SizedBox(height: 8),
                      Text(
                        post['content'] ?? '...',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 15, height: 1.5),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 20),
                      Divider(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildInteractionButton(context, Icons.translate_rounded, 'Translate'),
                          _buildInteractionButton(context, Icons.mode_comment_outlined, 'Comment'),
                          _buildInteractionButton(context, Icons.bookmark_border_rounded, 'Save'),
                          _buildInteractionButton(context, Icons.share_rounded, 'Share'),
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

  Widget _buildInteractionButton(BuildContext context, IconData icon, String label) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label feature coming soon!')));
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            SizedBox(width: 6),
            Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildRateChip(String label, String? value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.appleBlue),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.appleBlue),
          SizedBox(width: 6),
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Text(value ?? '...', style: TextStyle(color: Colors.black87, fontSize: 12)),
        ],
      ),
    );
  }
}
