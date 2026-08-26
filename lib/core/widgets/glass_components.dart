import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ==============================================================================
// GLASS COMPONENTS — Reusable glassmorphism widgets
// Apple-like backdrop blur + translucent fill aesthetic.
// ==============================================================================

// ── Atmospheric Background (aurora ambient blobs) ─────────────────────────────
class AtmosphericBackground extends StatelessWidget {
  final Widget child;
  final Color? primaryBlob;
  final Color? secondaryBlob;

  const AtmosphericBackground({
    super.key,
    required this.child,
    this.primaryBlob,
    this.secondaryBlob,
  });

  @override
  Widget build(BuildContext context) {
    final blob1 = primaryBlob ?? AppColors.primary.withValues(alpha: 0.12);
    final blob2 = secondaryBlob ?? AppColors.primaryLight.withValues(alpha: 0.08);

    return Container(
      color: AppColors.systemBackground,
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(shape: BoxShape.circle, color: blob1),
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: -80,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(shape: BoxShape.circle, color: blob2),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.06),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

// ── Glass Card ─────────────────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final Color fillColor;
  final Color borderColor;
  final double blurSigma;
  final List<BoxShadow>? shadows;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.borderRadius = 20,
    this.onTap,
    this.width,
    this.height,
    this.fillColor = const Color(0xCCFFFFFF),
    this.borderColor = const Color(0x1AFFFFFF),
    this.blurSigma = 20,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor, width: 0.5),
            boxShadow: shadows ??
                [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      card = GestureDetector(onTap: onTap, child: card);
    }

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    return card;
  }
}

// ── Glass Card Dark (for MMID pass, hero cards) ────────────────────────────────
class GlassCardDark extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final double? height;
  final Gradient? gradient;

  const GlassCardDark({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.borderRadius = 20,
    this.onTap,
    this.height,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final grad = gradient ??
        const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1C1C1E),
            AppColors.petrol,
          ],
        );

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            gradient: grad,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      card = GestureDetector(onTap: onTap, child: card);
    }
    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }
    return card;
  }
}

// ── Surface Card (white iOS-style grouped row card) ───────────────────────────
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final double? height;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.margin,
    this.borderRadius = 16,
    this.onTap,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.separator, width: 0.5),
      ),
      child: child,
    );

    if (onTap != null) {
      card = GestureDetector(
        onTap: onTap,
        child: card,
      );
    }
    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }
    return card;
  }
}

// ── Status Pill Badge ─────────────────────────────────────────────────────────
class PillBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;
  final bool dot;

  const PillBadge({
    super.key,
    required this.label,
    required this.color,
    this.textColor,
    this.dot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor ?? color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String label;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.label,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.tertiaryLabel,
          ),
        ),
        const Spacer(),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Shimmering Skeleton Loader ─────────────────────────────────────────────────
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.separator.withValues(alpha: _animation.value),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

// ── NavItem Data Class ─────────────────────────────────────────────────────────
class NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const NavItem(this.label, this.icon, this.activeIcon);
}

// ── Floating Pill Navigation Bar ───────────────────────────────────────────────
class PillNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<NavItem> items;
  final ValueChanged<int> onTap;

  const PillNavBar({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 66,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xF0FFFFFF),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: AppColors.separator, width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final active = selectedIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              active ? item.activeIcon : item.icon,
                              size: 20,
                              color: active ? Colors.white : AppColors.tertiaryLabel,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                                color: active ? Colors.white : AppColors.tertiaryLabel,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Convenience factory
List<NavItem> buildNavItems() => const [
  NavItem('Home', Icons.home_outlined, Icons.home_rounded),
  NavItem('Alerts', Icons.notifications_outlined, Icons.notifications_rounded),
  NavItem('Explore', Icons.explore_outlined, Icons.explore_rounded),
  NavItem('Account', Icons.person_outline_rounded, Icons.person_rounded),
];
