import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/locale_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: Text(ref.watch(isEnglishProvider) ? 'English' : 'Tamil'),
            trailing: Switch(
              value: !ref.watch(isEnglishProvider),
              onChanged: (val) {
                ref.read(isEnglishProvider.notifier).state = !val;
              },
            ),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Push Notifications'),
            trailing: Switch(value: true, onChanged: null),
          ),
        ],
      ),
    );
  }
}
