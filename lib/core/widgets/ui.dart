import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator, CupertinoSliverRefreshControl;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

// ==============================================================================
// UI KIT — the handful of primitives every screen is built from.
// iOS conventions: large collapsing titles, inset grouped lists, squircle corners,
// press-scale feedback, a sliding segmented control and a plain tab bar.
// ==============================================================================

RoundedSuperellipseBorder squircle(double r) =>
    RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(r));

const kCardShadow = [BoxShadow(color: Color(0x0D000000), blurRadius: 14, offset: Offset(0, 3))];

/// Draws a soft blurred shadow behind [child] using a plain rounded-rect layer. (Shadows
/// attached directly to a squircle ShapeDecoration can paint as a hard offset band.)
class SoftShadow extends StatelessWidget {
  final double radius;
  final List<BoxShadow> shadows;
  final Widget child;
  const SoftShadow({super.key, required this.radius, this.shadows = kCardShadow, required this.child});

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius), boxShadow: shadows),
        child: child,
      );
}

// ── Press feedback ─────────────────────────────────────────────────────────────
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;

  const Pressable({super.key, required this.child, this.onTap, this.scale = 0.97, this.haptic = false});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: () {
        if (widget.haptic) HapticFeedback.selectionClick();
        widget.onTap!();
      },
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

// ── Card ───────────────────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;
  final Color color;
  final Gradient? gradient;
  final bool shadow;
  final Clip clip;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.radius = AppSpacing.cardRadius,
    this.color = AppColors.card,
    this.gradient,
    this.shadow = true,
    this.clip = Clip.none,
  });

  @override
  Widget build(BuildContext context) {
    final surface = Container(
      clipBehavior: clip,
      decoration: ShapeDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        shape: squircle(radius),
      ),
      padding: padding,
      child: child,
    );
    final card = shadow ? SoftShadow(radius: radius, child: surface) : surface;
    return Pressable(onTap: onTap, scale: 0.985, child: card);
  }
}

// ── Large collapsing title (iOS navigation bar) ────────────────────────────────
class LargeTitleSliver extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final bool showBack;

  const LargeTitleSliver({super.key, required this.title, this.trailing, this.showBack = false});

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _LargeTitleDelegate(
        title: title,
        trailing: trailing,
        showBack: showBack,
        topPad: MediaQuery.paddingOf(context).top,
        onBack: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}

class _LargeTitleDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final Widget? trailing;
  final bool showBack;
  final double topPad;
  final VoidCallback onBack;

  static const _bar = 44.0;
  static const _large = 58.0;

  _LargeTitleDelegate({
    required this.title,
    required this.trailing,
    required this.showBack,
    required this.topPad,
    required this.onBack,
  });

  @override
  double get minExtent => topPad + _bar;
  @override
  double get maxExtent => topPad + _bar + _large;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / _large).clamp(0.0, 1.0);
    final largeOpacity = (1 - t * 1.6).clamp(0.0, 1.0);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.lerp(AppColors.background, Colors.white, t), // opaque when collapsed: no ghosting under the status bar
        border: Border(bottom: BorderSide(color: AppColors.hairline.withValues(alpha: 0.12 * t + (t > 0.98 ? 0.1 : 0)), width: 0.5)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: topPad,
            left: 0,
            right: 0,
            height: _bar,
            child: Row(
              children: [
                if (showBack)
                  Pressable(
                    onTap: onBack,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.primary),
                    ),
                  )
                else
                  const SizedBox(width: 56),
                Expanded(
                  child: Opacity(
                    opacity: t,
                    child: Text(title, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.headline),
                  ),
                ),
                SizedBox(width: 56, child: Align(alignment: Alignment.centerRight, child: Padding(padding: const EdgeInsets.only(right: 8), child: trailing))),
              ],
            ),
          ),
          Positioned(
            left: AppSpacing.gutter + 4,
            right: 64,
            bottom: 8,
            child: Opacity(
              opacity: largeOpacity,
              child: Transform.translate(
                offset: Offset(0, -6 * t),
                child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.largeTitle),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _LargeTitleDelegate old) =>
      old.title != title || old.topPad != topPad || old.showBack != showBack || old.trailing != trailing;
}

/// Round tinted icon button for a large-title bar (e.g. the "+" report button).
class BarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  const BarIconButton({super.key, required this.icon, required this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      haptic: true,
      child: Tooltip(
        message: tooltip ?? '',
        child: Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(color: AppColors.primaryTint, shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
      ),
    );
  }
}

// ── Grouped lists (iOS Settings style) ─────────────────────────────────────────
class GroupedSection extends StatelessWidget {
  final String? header;
  final String? footer;
  final List<Widget> children;
  final double dividerIndent;
  final EdgeInsetsGeometry margin;

  const GroupedSection({
    super.key,
    this.header,
    this.footer,
    required this.children,
    this.dividerIndent = 16,
    this.margin = const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, 22),
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i < children.length - 1) {
        rows.add(Divider(height: 0.5, thickness: 0.5, indent: dividerIndent, color: AppColors.hairline.withValues(alpha: 0.14)));
      }
    }
    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 7),
              child: Text(header!, style: AppTextStyles.footnote),
            ),
          Material(
            color: AppColors.card,
            shape: squircle(AppSpacing.rowRadius + 4),
            clipBehavior: Clip.antiAlias,
            child: Column(children: rows),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(footer!, style: AppTextStyles.caption1),
            ),
        ],
      ),
    );
  }
}

class IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const IconTile({super.key, required this.icon, required this.color, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(color: color, shape: squircle(size * 0.28)),
      child: Icon(icon, size: size * 0.6, color: Colors.white),
    );
  }
}

class GroupedRow extends StatelessWidget {
  final IconData? icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool chevron;
  final Color? titleColor;

  const GroupedRow({
    super.key,
    this.icon,
    this.iconColor = AppColors.primary,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.chevron = false,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: subtitle != null ? 11 : 12.5),
      child: Row(
        children: [
          if (icon != null) ...[IconTile(icon: icon!, color: iconColor), const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.body.copyWith(color: titleColor ?? AppColors.ink)),
                if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 1), child: Text(subtitle!, style: AppTextStyles.footnote)),
              ],
            ),
          ),
          if (value != null)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(value!, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end, style: AppTextStyles.body.copyWith(color: AppColors.tertiaryLabel)),
              ),
            ),
          if (trailing != null) Padding(padding: const EdgeInsets.only(left: 10), child: trailing!),
          if (chevron)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.quaternaryLabel),
            ),
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap!();
      },
      highlightColor: const Color(0x14000000),
      splashFactory: NoSplash.splashFactory,
      child: content,
    );
  }
}

// ── Segmented control (sliding thumb) ──────────────────────────────────────────
class SegmentedPill extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  const SegmentedPill({super.key, required this.labels, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final n = labels.length;
    // No LayoutBuilder: the thumb is positioned with alignment fractions, so this widget can
    // be measured by parents that need intrinsic sizes (e.g. SliverFillRemaining).
    final x = n <= 1 ? 0.0 : -1.0 + 2.0 * selected / (n - 1);
    return Container(
      height: 36,
      padding: const EdgeInsets.all(2),
      decoration: ShapeDecoration(color: AppColors.fill, shape: squircle(11)),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment(x, 0),
            child: FractionallySizedBox(
              widthFactor: 1 / n,
              heightFactor: 1,
              child: Container(
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: squircle(9),
                  shadows: const [BoxShadow(color: Color(0x1F000000), blurRadius: 4, offset: Offset(0, 1))],
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < n; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (i != selected) {
                        HapticFeedback.selectionClick();
                        onChanged(i);
                      }
                    },
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: AppTextStyles.footnote.copyWith(
                          fontWeight: FontWeight.w600,
                          color: i == selected ? AppColors.ink : AppColors.secondaryLabel,
                        ),
                        child: Text(labels[i], maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Filter pills ───────────────────────────────────────────────────────────────
class FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const FilterPill({super.key, required this.label, required this.selected, required this.onTap, this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      haptic: true,
      scale: 0.95,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected ? const [] : const [BoxShadow(color: Color(0x0D000000), blurRadius: 6, offset: Offset(0, 1))],
        ),
        child: Text(
          label,
          style: AppTextStyles.subheadline.copyWith(fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.ink),
        ),
      ),
    );
  }
}

class FilterRail extends StatelessWidget {
  final List<Widget> pills;
  const FilterRail({super.key, required this.pills});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: MediaQuery.removePadding(
        context: context,
        removeLeft: true,
        removeRight: true,
        child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        itemCount: pills.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => pills[i],
      ),
      ),
    );
  }
}

// ── Buttons ────────────────────────────────────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Color color;
  final bool tinted;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.color = AppColors.primary,
    this.tinted = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final fg = tinted ? color : Colors.white;
    return Pressable(
      onTap: enabled ? onPressed : null,
      haptic: true,
      scale: 0.98,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: (onPressed == null && !loading) ? 0.4 : 1,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: tinted ? color.withValues(alpha: 0.12) : color,
            shape: squircle(16),
          ),
          child: loading
              ? CupertinoActivityIndicator(color: fg)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[Icon(icon, size: 20, color: fg), const SizedBox(width: 8)],
                    Flexible(
                      child: Text(
                        label,
                        style: AppTextStyles.headline.copyWith(color: fg),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Tags, avatar, states ───────────────────────────────────────────────────────
class Tag extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const Tag({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: ShapeDecoration(color: color.withValues(alpha: 0.12), shape: squircle(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 4)],
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption1.copyWith(color: color, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  final String? url;
  final String name;
  final double size;
  const Avatar({super.key, this.url, required this.name, this.size = 60});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'H' : String.fromCharCode(name.trim().runes.first).toUpperCase();
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF3B9BFF), Color(0xFF6B4DE6)]),
      ),
      child: Text(initial, style: AppTextStyles.title2.copyWith(color: Colors.white, fontSize: size * 0.4)),
    );
    if (url == null || url!.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder: (_, child, progress) => progress == null ? child : fallback,
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({super.key, required this.icon, required this.title, this.body, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: AppColors.fill, shape: BoxShape.circle),
            child: Icon(icon, size: 30, color: AppColors.tertiaryLabel),
          ),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: AppTextStyles.title3),
          if (body != null) ...[
            const SizedBox(height: 6),
            Text(body!, textAlign: TextAlign.center, style: AppTextStyles.subheadline.copyWith(color: AppColors.secondaryLabel)),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: 18),
            SizedBox(width: 180, child: PrimaryButton(label: actionLabel!, onPressed: onAction, tinted: true)),
          ],
        ],
      ),
    );
  }
}

class Banner2 extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback? onTap;
  const Banner2({super.key, required this.icon, required this.text, this.color = AppColors.primary, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: ShapeDecoration(color: color.withValues(alpha: 0.10), shape: squircle(16)),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: AppTextStyles.subheadline.copyWith(color: color, fontWeight: FontWeight.w600))),
            if (onTap != null) Icon(Icons.chevron_right_rounded, size: 20, color: color.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton ───────────────────────────────────────────────────────────────────
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;
  const SkeletonBox({super.key, this.width, required this.height, this.radius = 8});

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(const Color(0xFFE6E6EB), const Color(0xFFF1F1F5), _c.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// iOS pull-to-refresh sliver (works with the app-wide bouncing physics).
Widget refreshSliver(Future<void> Function() onRefresh) => CupertinoSliverRefreshControl(onRefresh: onRefresh);

// ── Tab bar ────────────────────────────────────────────────────────────────────
class TabSpec {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final int badge; // 0 = none; > 0 shows a count bubble
  const TabSpec(this.label, this.icon, this.activeIcon, {this.badge = 0});
}

/// Rounded floating tab bar. One capsule slides under the selected tab; nothing else changes size while
/// animating (no font-weight or layout changes), so switching tabs is smooth. Works for 4 to 6 tabs.
class AppTabBar extends StatelessWidget {
  final int selected;
  final List<TabSpec> tabs;
  final ValueChanged<int> onTap;

  static const double height = 64;

  const AppTabBar({super.key, required this.selected, required this.tabs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final n = tabs.length;
    final x = n <= 1 ? 0.0 : -1.0 + 2.0 * selected / (n - 1);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
        child: SoftShadow(
          radius: 34,
          shadows: const [BoxShadow(color: Color(0x1F000000), blurRadius: 22, offset: Offset(0, 8))],
          child: Container(
            height: height,
            padding: const EdgeInsets.all(6),
            decoration: ShapeDecoration(color: const Color(0xFBFFFFFF), shape: squircle(34)),
            child: Stack(
              children: [
                AnimatedAlign(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment(x, 0),
                  child: FractionallySizedBox(
                    widthFactor: 1 / n,
                    heightFactor: 1,
                    child: Container(decoration: ShapeDecoration(color: AppColors.primaryTint, shape: squircle(26))),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < n; i++)
                      Expanded(
                        child: _TabItem(
                          spec: tabs[i],
                          active: i == selected,
                          onTap: () {
                            if (i != selected) HapticFeedback.selectionClick();
                            onTap(i);
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final TabSpec spec;
  final bool active;
  final VoidCallback onTap;
  const _TabItem({required this.spec, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.tertiaryLabel;
    return Semantics(
      button: true,
      selected: active,
      label: spec.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: active ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutBack,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: color),
                    duration: const Duration(milliseconds: 220),
                    builder: (_, c, __) => Icon(active ? spec.activeIcon : spec.icon, size: 24, color: c),
                  ),
                  if (spec.badge > 0)
                    Positioned(
                      right: -8,
                      top: -5,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 16),
                        height: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white, width: 1.5)),
                        child: Text(spec.badge > 99 ? '99+' : '${spec.badge}', style: const TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white, height: 1.1)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            // fixed style + FittedBox: labels never change size, and long Tamil words shrink instead of clipping
            SizedBox(
              height: 13,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: color),
                  duration: const Duration(milliseconds: 220),
                  builder: (_, c, __) => Text(spec.label, maxLines: 1, style: TextStyle(fontFamily: 'Inter', fontSize: 10.5, fontWeight: FontWeight.w500, color: c, height: 1.2)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fades + nudges its child each time [token] changes (used for tab content).
class FadeOnChange extends StatefulWidget {
  final Object token;
  final Widget child;
  const FadeOnChange({super.key, required this.token, required this.child});

  @override
  State<FadeOnChange> createState() => _FadeOnChangeState();
}

class _FadeOnChangeState extends State<FadeOnChange> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 220), value: 1);
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void didUpdateWidget(covariant FadeOnChange old) {
    super.didUpdateWidget(old);
    if (old.token != widget.token) _c.forward(from: 0.0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1).animate(_a),
      child: widget.child,
    );
  }
}

// ── Brand ──────────────────────────────────────────────────────────────────────
/// The MyHarur logo (assets/brand/logo.png, tight-cropped, transparent background).
class BrandLogo extends StatelessWidget {
  static const asset = 'assets/brand/logo.png';
  static const aspect = 900 / 605; // width / height of the asset

  final double width;
  const BrandLogo({super.key, this.width = 160});

  @override
  Widget build(BuildContext context) => Image.asset(
        asset,
        width: width,
        height: width / aspect,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        semanticLabel: 'MyHarur',
      );
}
