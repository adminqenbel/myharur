import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/locale_provider.dart';
import '../theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Select Language', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                title: const Text('English'),
                trailing: ref.watch(isEnglishProvider) ? const Icon(Icons.check, color: AppTheme.accent) : null,
                onTap: () {
                  ref.read(isEnglishProvider.notifier).state = true;
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('Tamil'),
                trailing: !ref.watch(isEnglishProvider) ? const Icon(Icons.check, color: AppTheme.accent) : null,
                onTap: () {
                  ref.read(isEnglishProvider.notifier).state = false;
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      }
    );
  }

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
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguagePicker(context, ref),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Push Notifications'),
            trailing: Switch(
              value: true, 
              onChanged: null,
              activeColor: AppTheme.accent,
            ),
          ),
        ],
      ),
    );
  }
}
