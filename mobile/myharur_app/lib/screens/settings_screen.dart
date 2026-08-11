import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(useRootNavigator: true, 
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Select Language', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                title: Text('English'),
                trailing: ref.watch(isEnglishProvider) ? Icon(Icons.check, color: AppTheme.accent) : null,
                onTap: () {
                  ref.read(isEnglishProvider.notifier).state = true;
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: Text('Tamil'),
                trailing: !ref.watch(isEnglishProvider) ? Icon(Icons.check, color: AppTheme.accent) : null,
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

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(useRootNavigator: true, 
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Select Theme', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                title: Text('System Default'),
                trailing: ref.watch(themeProvider) == ThemeMode.system ? Icon(Icons.check, color: AppTheme.accent) : null,
                onTap: () {
                  ref.read(themeProvider.notifier).setTheme(ThemeMode.system);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: Text('Light'),
                trailing: ref.watch(themeProvider) == ThemeMode.light ? Icon(Icons.check, color: AppTheme.accent) : null,
                onTap: () {
                  ref.read(themeProvider.notifier).setTheme(ThemeMode.light);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: Text('Dark'),
                trailing: ref.watch(themeProvider) == ThemeMode.dark ? Icon(Icons.check, color: AppTheme.accent) : null,
                onTap: () {
                  ref.read(themeProvider.notifier).setTheme(ThemeMode.dark);
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
    final themeMode = ref.watch(themeProvider);
    String themeLabel = 'System';
    if (themeMode == ThemeMode.light) themeLabel = 'Light';
    if (themeMode == ThemeMode.dark) themeLabel = 'Dark';

    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          ListTile(
            leading: Icon(Icons.language),
            title: Text('Language'),
            subtitle: Text(ref.watch(isEnglishProvider) ? 'English' : 'Tamil'),
            trailing: Icon(Icons.chevron_right),
            onTap: () => _showLanguagePicker(context, ref),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.brightness_6),
            title: Text('Theme'),
            subtitle: Text(themeLabel),
            trailing: Icon(Icons.chevron_right),
            onTap: () => _showThemePicker(context, ref),
          ),
          Divider(),
          ListTile(
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
