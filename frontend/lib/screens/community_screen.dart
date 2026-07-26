import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/locale_provider.dart';
import '../l10n/translations.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l(ref, 'Community Hub')),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.forum, size: 80, color: Colors.purple),
            const SizedBox(height: 16),
            Text(l(ref, 'Community Hub'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Local Questions, Polls, and Events will appear here.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
