import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_components.dart';

// ==============================================================================
// ACCOUNT PAGE — Profile, settings, profile editing, and sign out
// ==============================================================================
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  void _openEditProfileDialog() {
    final profile = AuthService.currentProfile;
    final nameCtrl = TextEditingController(text: profile.fullName);
    final phoneCtrl = TextEditingController(text: profile.phone);
    final ecNameCtrl = TextEditingController(text: profile.emergencyContactName);
    final ecPhoneCtrl = TextEditingController(text: profile.emergencyContactPhone);
    int? selectedWard = profile.wardId;
    String selectedBlood = profile.bloodGroup.isNotEmpty ? profile.bloodGroup : 'O+';
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.separator,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Edit Profile', style: AppTextStyles.title2),
                const SizedBox(height: 16),

                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<int>(
                  initialValue: selectedWard,
                  decoration: const InputDecoration(labelText: 'Ward'),
                  hint: const Text('Select Ward (1-18)'),
                  items: List.generate(18, (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text('Ward ${i + 1}'),
                  )),
                  onChanged: (v) => setModalState(() => selectedWard = v),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  initialValue: selectedBlood,
                  decoration: const InputDecoration(labelText: 'Blood Group'),
                  items: ['O+', 'A+', 'B+', 'AB+', 'O-', 'A-', 'B-', 'AB-']
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (v) => setModalState(() => selectedBlood = v ?? 'O+'),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: ecNameCtrl,
                  decoration: const InputDecoration(labelText: 'Emergency Contact Name'),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: ecPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Emergency Contact Phone'),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: saving ? null : () async {
                    setModalState(() => saving = true);
                    // Cache BuildContext-dependent objects BEFORE the await
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(modalCtx);
                    final ok = await AuthService.saveProfile(
                      fullName: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      wardId: selectedWard,
                      wardLocality: selectedWard != null ? 'Ward $selectedWard' : null,
                      bloodGroup: selectedBlood,
                      emergencyContactName: ecNameCtrl.text.trim(),
                      emergencyContactPhone: ecPhoneCtrl.text.trim(),
                    );
                    if (!mounted) return;
                    navigator.pop();
                    setState(() {});
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(ok ? 'Profile updated!' : 'Failed to update profile.'),
                        backgroundColor: ok ? AppColors.success : AppColors.danger,
                      ),
                    );
                  },
                  child: saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = AuthService.currentProfile;

    return AtmosphericBackground(
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Account', style: AppTextStyles.largeTitle),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                      onPressed: _openEditProfileDialog,
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: GlassCardDark(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        backgroundImage: profile.avatarUrl != null
                            ? NetworkImage(profile.avatarUrl!)
                            : null,
                        child: profile.avatarUrl == null
                            ? Text(
                                profile.fullName.isNotEmpty
                                    ? profile.fullName[0].toUpperCase()
                                    : 'H',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '@${profile.username}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            PillBadge(
                              label: profile.primaryRole.toUpperCase(),
                              color: Colors.white,
                              textColor: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      label: 'IDENTITY',
                      action: 'Edit',
                      onAction: _openEditProfileDialog,
                    ),
                    const SizedBox(height: 10),
                    SurfaceCard(
                      child: Column(
                        children: [
                          _InfoRow(label: 'MMID', value: profile.mmid),
                          const Divider(height: 1),
                          _InfoRow(
                            label: 'Email',
                            value: profile.email.isNotEmpty ? profile.email : '\u2014',
                          ),
                          const Divider(height: 1),
                          _InfoRow(label: 'Ward', value: profile.wardLocality),
                          const Divider(height: 1),
                          _InfoRow(
                            label: 'Phone',
                            value: profile.phone.isNotEmpty ? profile.phone : '\u2014',
                          ),
                          const Divider(height: 1),
                          _InfoRow(
                            label: 'Blood Group',
                            value: profile.bloodGroup.isNotEmpty ? profile.bloodGroup : '\u2014',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const SectionHeader(label: 'EMERGENCY'),
                    const SizedBox(height: 10),
                    SurfaceCard(
                      child: Column(
                        children: [
                          _InfoRow(
                            label: 'Contact Name',
                            value: profile.emergencyContactName.isNotEmpty
                                ? profile.emergencyContactName
                                : '\u2014',
                          ),
                          const Divider(height: 1),
                          _InfoRow(
                            label: 'Contact Phone',
                            value: profile.emergencyContactPhone.isNotEmpty
                                ? profile.emergencyContactPhone
                                : '\u2014',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const SectionHeader(label: 'ACCOUNT ACTIONS'),
                    const SizedBox(height: 10),

                    SurfaceCard(
                      child: Column(
                        children: [
                          _ActionRow(
                            icon: Icons.logout_rounded,
                            label: 'Sign Out',
                            color: AppColors.danger,
                            onTap: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Sign Out'),
                                  content: const Text('Are you sure you want to sign out?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text(
                                        'Sign Out',
                                        style: TextStyle(color: AppColors.danger),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) await AuthService.signOut();
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    Center(
                      child: Text(
                        'MyHarur v1.0.0 \u2014 A QenBel product',
                        style: AppTextStyles.caption2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.footnote.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.subheadline.copyWith(color: AppColors.secondaryLabel),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(label, style: AppTextStyles.subheadline.copyWith(color: color)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: AppColors.tertiaryLabel, size: 18),
          ],
        ),
      ),
    );
  }
}
