import 'package:flutter/material.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/services/ads_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/safe_launch.dart';
import '../../core/widgets/ui.dart';

// ==============================================================================
// SPONSORED CARD — a local business ad, managed by a super admin (Account > Admin panel > Ads).
// One placement shows at most one ad (the highest-priority active one), clearly labelled "Sponsored".
// Renders nothing when there is none, so the app looks exactly as it does today until an ad exists.
// Only an aggregate view/tap count is recorded — nothing about the viewer.
// ==============================================================================
class SponsoredCard extends StatefulWidget {
  final String placement; // home | news | reports
  const SponsoredCard({super.key, required this.placement});

  @override
  State<SponsoredCard> createState() => _SponsoredCardState();
}

class _SponsoredCardState extends State<SponsoredCard> {
  Ad? _ad;
  bool _countedImpression = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ads = await AdsService.activeAds(widget.placement, limit: 1);
    if (!mounted) return;
    final ad = ads.isEmpty ? null : ads.first;
    setState(() => _ad = ad);
    if (ad != null && !_countedImpression) {
      _countedImpression = true;
      AdsService.recordImpression(ad.id);
    }
  }

  Future<void> _open() async {
    final ad = _ad;
    if (ad == null) return;
    AdsService.recordClick(ad.id);
    await safeLaunch(ad.linkUrl);
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null) return const SizedBox.shrink();
    final t = context.t;
    final imageUrl = ad.imageUrl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, 14),
      child: AppCard(
        onTap: _open,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageUrl != null) ...[
              ClipPath(
                clipper: ShapeBorderClipper(shape: squircle(14)),
                child: Image.network(imageUrl, height: 130, width: double.infinity, fit: BoxFit.cover, gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              ),
              const SizedBox(height: 12),
            ],
            Tag(label: t.sponsored, color: AppColors.tertiaryLabel, icon: Icons.campaign_outlined),
            const SizedBox(height: 8),
            Text(ad.title, style: AppTextStyles.headline, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(ad.body, style: AppTextStyles.subheadline.copyWith(color: AppColors.secondaryLabel), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
