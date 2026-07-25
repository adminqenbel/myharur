import 'package:flutter/material.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Harur News'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create Post feature coming soon!')))),
        ],
      ),
      body: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text('User $index'),
                  subtitle: const Text('2 hours ago'),
                  trailing: const Icon(Icons.more_vert),
                ),
                Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(child: Icon(Icons.image, size: 50)),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Breaking News $index: Something happened in Harur today.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
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
      ),
    );
  }
}
