import 'package:flutter/material.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/models/alert.dart';
import '../../core/services/alerts_service.dart';
import '../../core/services/safety_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';
import '../reports/alert_widgets.dart';

String postStatusLabel(AppLocalizations t, Alert a) => switch (a.status) {
      'published' => a.isExpired ? t.statusExpired : t.statusPublished,
      'pending' => t.statusPending,
      'rejected' => t.statusRejected,
      _ => t.statusExpired,
    };

Color postStatusColor(Alert a) => switch (a.status) {
      'published' => a.isExpired ? AppColors.tertiaryLabel : AppColors.success,
      'pending' => AppColors.warning,
      'rejected' => AppColors.danger,
      _ => AppColors.tertiaryLabel,
    };

// ==============================================================================
// MY POSTS: everything the person submitted (reports and news), with its review status.
// Open one to read it or delete it. Deleting hides it at once; the files are purged after 30 days.
// ==============================================================================
class MyPostsPage extends StatefulWidget {
  const MyPostsPage({super.key});

  @override
  State<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage> {
  List<Alert>? _posts;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await AlertsService.fetchMine();
    if (!mounted) return;
    setState(() {
      _posts = r ?? _posts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final posts = _posts ?? const <Alert>[];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          LargeTitleSliver(title: t.myPosts, showBack: true),
          refreshSliver(_load),
          if (_loading)
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())))
          else if (posts.isEmpty)
            SliverToBoxAdapter(child: EmptyState(icon: Icons.edit_note_rounded, title: t.myPostsEmpty))
          else
            SliverToBoxAdapter(
              child: GroupedSection(
                dividerIndent: 58,
                children: [
                  for (final a in posts)
                    GroupedRow(
                      icon: a.category.categoryIconData,
                      iconColor: a.category.categoryColor,
                      title: a.title,
                      subtitle: '${postStatusLabel(t, a)} · ${context.timeAgo(a.createdAt)}',
                      chevron: true,
                      onTap: () => showAlertDetail(context, a, onChanged: _load),
                    ),
                ],
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ==============================================================================
// BLOCKED AUTHORS: people whose posts the person hid. Only the title of the post that was blocked is
// stored, never the author's name (residents cannot see who wrote a post).
// ==============================================================================
class BlockedAuthorsPage extends StatefulWidget {
  const BlockedAuthorsPage({super.key});

  @override
  State<BlockedAuthorsPage> createState() => _BlockedAuthorsPageState();
}

class _BlockedAuthorsPageState extends State<BlockedAuthorsPage> {
  List<BlockedAuthor>? _blocked;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await SafetyService.myBlocks();
    if (!mounted) return;
    setState(() {
      _blocked = r ?? _blocked;
      _loading = false;
    });
  }

  Future<void> _unblock(BlockedAuthor b) async {
    final ok = await SafetyService.unblock(b.userId);
    if (ok) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final list = _blocked ?? const <BlockedAuthor>[];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          LargeTitleSliver(title: t.blockedAuthors, showBack: true),
          if (_loading)
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())))
          else if (list.isEmpty)
            SliverToBoxAdapter(child: EmptyState(icon: Icons.block_rounded, title: t.blockedEmpty))
          else
            SliverToBoxAdapter(
              child: GroupedSection(
                children: [
                  for (final b in list)
                    GroupedRow(
                      title: b.label.isEmpty ? '—' : b.label,
                      trailing: TextButton(onPressed: () => _unblock(b), child: Text(t.unblock)),
                    ),
                ],
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}
