import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../l10n/translations.dart';
import '../theme.dart';
import '../widgets/design_system.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(authProvider.notifier).refreshUser();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user ?? {};
    final profile = user['profile'] as Map<String, dynamic>? ?? {};
    final role = user['role'] as Map<String, dynamic>? ?? {};

    final firstName = profile['first_name'] ?? '';
    final lastName = profile['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final email = user['email'] ?? 'No Email';
    final phone = profile['phone'] ?? 'Not set';
    final address = profile['address'] ?? 'Not set';
    final avatarUrl = profile['avatar_url'] as String?;
    final streak = profile['streak_days'] ?? 0;
    final rewards = profile['reward_points'] ?? 0;
    final roles = auth.roles;
    final roleName = roles.isNotEmpty ? roles.join(', ') : 'Citizen';
    final mid = user['mid'] ?? '—';
    final username = user['username'] as String?;
    final displayName = user['display_name'] as String?;
    final isSetup = user['is_setup_complete'] == true;
    final provider = user['login_provider'] ?? 'email';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Hero App Bar with Cover + Avatar overlap
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Cover Image
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: const [AppTheme.appleBlue, AppTheme.appleBlue],
                      ),
                    ),
                  ),
                  // Avatar Overlap
                  Positioned(
                    top: 130,
                    left: 24,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: MHAvatar(url: avatarUrl, radius: 50, fallback: fullName.isNotEmpty ? fullName[0] : null),
                    ),
                  ),
                  // User Details next to Avatar
                  Positioned(
                    top: 190,
                    left: 140,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName.isEmpty
                              ? (displayName ?? (username != null ? '@$username' : (isSetup ? email : 'Complete Your Profile')))
                              : fullName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (username != null)
                          Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Text('@$username', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7))),
                          ),
                      ],
                    ),
                  ),
                  // Status Chip top right
                  Positioned(
                    top: 48,
                    right: 16,
                    child: MHBadge(
                      text: roleName,
                      color: auth.isSuperAdmin ? AppTheme.accent : AppTheme.info,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
                  child: Icon(Icons.settings_rounded, color: Theme.of(context).colorScheme.surface, size: 20),
                ),
                onPressed: () => context.push('/settings'),
              ),
              SizedBox(width: 8),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SizedBox(height: 24),
                  // Stats Row
                  MHCard(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _stat('${streak}', 'Day Streak', Icons.local_fire_department_rounded, AppTheme.accent),
                        Container(width: 1, height: 40, color: Theme.of(context).dividerColor),
                        _stat('${rewards}', 'Reputation', Icons.workspace_premium_rounded, AppTheme.accent),
                        Container(width: 1, height: 40, color: Theme.of(context).dividerColor),
                        _stat(roleName, 'Role', Icons.shield_rounded, AppTheme.info),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Member ID (MID) Callout
                  MHCard(
                    padding: EdgeInsets.all(16),
                    onTap: () {
                      // copy to clipboard logic could go here
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Member ID copied')));
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppTheme.info.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.badge_rounded, color: AppTheme.info, size: 24),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Member ID', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                              Text(mid, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                            ],
                          ),
                        ),
                        Icon(Icons.copy_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), size: 20),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Profile Details
                  _section('Personal Info', [
                    _tile(Icons.email_rounded, 'Email', email),
                    _tile(Icons.phone_rounded, 'Phone', phone),
                    _tile(Icons.home_rounded, 'Address', address),
                  ]),
                  SizedBox(height: 16),

                  // Account Actions
                  _section('Account', [
                    _actionTile(Icons.edit_rounded, 'Edit Profile', AppTheme.info, () => context.push('/edit-profile')),
                    if (provider != 'google')
                      _actionTile(Icons.lock_outline_rounded, 'Change Password', AppTheme.accent, () => context.push('/change-password')),
                    if (provider == 'google')
                      _actionTile(Icons.lock_open_rounded, 'Set Password', Colors.purple, () => context.push('/set-password')),
                    if (auth.isAdmin)
                      _actionTile(Icons.admin_panel_settings_rounded, 'Admin Dashboard', AppTheme.danger, () => context.push('/admin')),
                  ]),
                  SizedBox(height: 24),

                  _section('Preferences', [
                    _actionTile(Icons.translate_rounded, 'Language Settings', AppTheme.success, () => context.push('/settings')),
                    _actionTile(Icons.notifications_outlined, 'Notifications', AppTheme.info, () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Notifications coming soon!')));
                    }),
                    _actionTile(Icons.help_outline_rounded, 'Help & Support', AppTheme.success, () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Help & Support coming soon!')));
                    }),
                  ]),
                  SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.logout, color: AppTheme.danger),
                      label: Text('Logout', style: TextStyle(color: AppTheme.danger, fontSize: 16)),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppTheme.danger),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (mounted) context.go('/login');
                      },
                    ),
                  ),
                  SizedBox(height: 100), // padding for nav bar
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color),
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
      ],
    );
  }

  Widget _section(String title, List<Widget> tiles) {
    return MHCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), letterSpacing: 0.5)),
          ),
          ...tiles,
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
      title: Text(label, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
      subtitle: Text(value, style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500)),
    );
  }

  Widget _actionTile(IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(fontSize: 15)),
      trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
      onTap: onTap,
    );
  }
}
