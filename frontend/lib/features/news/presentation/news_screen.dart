import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<List<dynamic>> _newsFuture;

  @override
  void initState() {
    super.initState();
    _newsFuture = _fetchNews();
  }

  Future<List<dynamic>> _fetchNews() async {
    final response = await ApiClient.dio.get('/news/');
    return response.data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyHarur News'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create Post feature coming soon!')))),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _newsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading news: ${snapshot.error}'));
          }

          final news = snapshot.data ?? [];
          if (news.isEmpty) {
            return const Center(child: Text('No news posts yet.'));
          }

          return ListView.builder(
            itemCount: news.length,
            itemBuilder: (context, index) {
              final post = news[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(post['author_name'] ?? 'Unknown User'),
                      subtitle: const Text('Recently'),
                      trailing: const Icon(Icons.more_vert),
                    ),
                    if (post['image_url'] != null)
                      Image.network(post['image_url'])
                    else
                      Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(child: Icon(Icons.image, size: 50)),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        post['title'] ?? 'No Title',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (post['content'] != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(post['content']),
                      ),
                    ButtonBar(
                      children: [
                        TextButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Liked!'))), icon: const Icon(Icons.thumb_up_alt_outlined), label: const Text('Like')),
                        TextButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening comments...'))), icon: const Icon(Icons.comment_outlined), label: const Text('Comment')),
                        TextButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sharing...'))), icon: const Icon(Icons.share_outlined), label: const Text('Share')),
                      ],
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
