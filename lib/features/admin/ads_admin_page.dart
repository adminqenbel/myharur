import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/services/ads_service.dart';
import '../../core/services/photo_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/safe_launch.dart';
import '../../core/widgets/ui.dart';

// ==============================================================================
// ADS (super admin, two-factor session required). Local sponsored cards: create, activate/pause, delete.
// Shown as clearly labelled "Sponsored" cards in Home, News and Reports (see SponsoredCard) — one per
// placement, highest priority first, only while active and inside its date range. Only aggregate view/tap
// counts are kept; nothing about who saw or tapped an ad.
// ==============================================================================
class AdsAdminPage extends StatefulWidget {
  const AdsAdminPage({super.key});

  @override
  State<AdsAdminPage> createState() => _AdsAdminPageState();
}

class _AdsAdminPageState extends State<AdsAdminPage> {
  List<Ad>? _ads;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await AdsService.adminList();
    if (!mounted) return;
    setState(() {
      _ads = r ?? _ads;
      _loading = false;
    });
  }

  Future<void> _create() async {
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => const _CreateAdSheet());
    _load();
  }

  Future<void> _setStatus(Ad ad, String status) async {
    final ok = await AdsService.setStatus(ad.id, status);
    if (ok) _load();
  }

  Future<void> _delete(Ad ad) async {
    final t = context.t;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.adDelete),
        content: Text(t.adDeleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.delete, style: const TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok == true && await AdsService.delete(ad.id)) _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final ads = _ads ?? const <Ad>[];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          LargeTitleSliver(title: t.adsAdmin, trailing: BarIconButton(icon: Icons.add_rounded, tooltip: t.adCreate, onTap: _create)),
          refreshSliver(_load),
          if (_loading)
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())))
          else if (ads.isEmpty)
            SliverToBoxAdapter(child: EmptyState(icon: Icons.campaign_outlined, title: t.adNone, actionLabel: t.adCreate, onAction: _create))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, 24),
              sliver: SliverList.separated(
                itemCount: ads.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _AdRow(ad: ads[i], onStatus: (s) => _setStatus(ads[i], s), onDelete: () => _delete(ads[i])),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdRow extends StatelessWidget {
  final Ad ad;
  final ValueChanged<String> onStatus;
  final VoidCallback onDelete;
  const _AdRow({required this.ad, required this.onStatus, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final statusColor = switch (ad.status) {
      'active' => AppColors.success,
      'paused' => AppColors.warning,
      _ => AppColors.tertiaryLabel,
    };
    final statusLabel = switch (ad.status) {
      'active' => t.adStatusActive,
      'paused' => t.adStatusPaused,
      _ => t.adStatusDraft,
    };
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(ad.title, style: AppTextStyles.headline, maxLines: 1, overflow: TextOverflow.ellipsis)),
            Tag(label: statusLabel, color: statusColor),
          ]),
          const SizedBox(height: 4),
          Text(ad.body, style: AppTextStyles.subheadline.copyWith(color: AppColors.secondaryLabel), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Text('${ad.placement} · ${t.adStats(ad.impressions, ad.clicks)}', style: AppTextStyles.caption1),
          const SizedBox(height: 12),
          Row(children: [
            if (ad.status != 'active') Expanded(child: PrimaryButton(label: t.adActivate, tinted: true, onPressed: () => onStatus('active')))
            else Expanded(child: PrimaryButton(label: t.adPause, tinted: true, color: AppColors.warning, onPressed: () => onStatus('paused'))),
            const SizedBox(width: 10),
            IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger)),
          ]),
        ],
      ),
    );
  }
}

class _CreateAdSheet extends StatefulWidget {
  const _CreateAdSheet();
  @override
  State<_CreateAdSheet> createState() => _CreateAdSheetState();
}

class _CreateAdSheetState extends State<_CreateAdSheet> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _link = TextEditingController();
  final _priority = TextEditingController(text: '0');
  String _placement = 'home';
  DateTime _starts = DateTime.now();
  DateTime? _ends;
  Uint8List? _image;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _link.dispose();
    _priority.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await PhotoService.pickFromGallery(limit: 1);
    if (picked.isEmpty) return;
    final bytes = await PhotoService.prepare(picked.first);
    if (bytes != null && mounted) setState(() => _image = bytes);
  }

  Future<void> _create() async {
    final t = context.t;
    final title = _title.text.trim();
    final body = _body.text.trim();
    final link = _link.text.trim();
    final uri = parseSafeUri(link);
    if (title.length < 3 || body.length < 3 || uri == null || uri.scheme != 'https') {
      setState(() => _error = t.adCreateFailed);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    String? imagePath;
    if (_image != null) imagePath = await AdsService.uploadImage(_image!);
    final err = await AdsService.create(
      title: title,
      body: body,
      imagePath: imagePath,
      link: link,
      placement: _placement,
      priority: int.tryParse(_priority.text.trim()) ?? 0,
      startsAt: _starts,
      endsAt: _ends,
    );
    if (!mounted) return;
    if (err == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _busy = false;
        _error = t.adCreateFailed;
      });
    }
  }

  Future<void> _pickStarts() async {
    final d = await showDatePicker(context: context, initialDate: _starts, firstDate: DateTime.now().subtract(const Duration(days: 1)), lastDate: DateTime.now().add(const Duration(days: 730)));
    if (d != null) setState(() => _starts = d);
  }

  Future<void> _pickEnds() async {
    final d = await showDatePicker(context: context, initialDate: _ends ?? _starts, firstDate: _starts, lastDate: DateTime.now().add(const Duration(days: 730)));
    if (d != null) setState(() => _ends = d);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.adCreate, style: AppTextStyles.title2),
              const SizedBox(height: 14),
              TextField(controller: _title, maxLength: 100, decoration: InputDecoration(labelText: t.adTitleLabel)),
              TextField(controller: _body, maxLength: 300, minLines: 2, maxLines: 4, decoration: InputDecoration(labelText: t.adBodyLabel)),
              TextField(controller: _link, keyboardType: TextInputType.url, decoration: InputDecoration(labelText: t.adLinkLabel)),
              const SizedBox(height: 10),
              Text(t.adPlacementLabel, style: AppTextStyles.footnote),
              const SizedBox(height: 6),
              SegmentedPill(
                labels: [t.adPlacementHome, t.adPlacementNews, t.adPlacementReports],
                selected: ['home', 'news', 'reports'].indexOf(_placement),
                onChanged: (i) => setState(() => _placement = ['home', 'news', 'reports'][i]),
              ),
              const SizedBox(height: 14),
              TextField(controller: _priority, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: t.adPriorityLabel)),
              const SizedBox(height: 10),
              GroupedSection(margin: EdgeInsets.zero, dividerIndent: 58, children: [
                GroupedRow(icon: Icons.event_rounded, iconColor: AppColors.primary, title: t.adStartsLabel, value: _fmt(_starts), chevron: true, onTap: _pickStarts),
                GroupedRow(icon: Icons.event_busy_rounded, iconColor: AppColors.tertiaryLabel, title: t.adEndsLabel, value: _ends == null ? t.notSet : _fmt(_ends!), chevron: true, onTap: _pickEnds),
              ]),
              const SizedBox(height: 10),
              Pressable(
                onTap: _pickImage,
                child: Container(
                  height: 90,
                  decoration: ShapeDecoration(color: AppColors.fill, shape: squircle(14)),
                  child: _image == null
                      ? Center(child: Text(t.adImageOptional, style: AppTextStyles.subheadline.copyWith(color: AppColors.primary)))
                      : ClipPath(clipper: ShapeBorderClipper(shape: squircle(14)), child: Image.memory(_image!, fit: BoxFit.cover, width: double.infinity)),
                ),
              ),
              if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: AppTextStyles.footnote.copyWith(color: AppColors.danger))),
              const SizedBox(height: 16),
              PrimaryButton(label: t.adCreate, loading: _busy, onPressed: _create),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
