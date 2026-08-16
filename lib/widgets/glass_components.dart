import 'dart:ui';
import 'package:flutter/material.dart';

enum GlassLevel { level1, level2, level3 }

class GlassSurface extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final Border? border;
  final Gradient? gradient;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? boxShadow;

  const GlassSurface({
    super.key,
    required this.child,
    this.blur = 18.0,
    this.opacity = 0.85,
    this.borderRadius,
    this.border,
    this.gradient,
    this.color,
    this.padding,
    this.margin,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(22);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultColor = color ?? (isDark ? const Color(0xFF1C1C1E) : Colors.white).withValues(alpha: opacity);
    final defaultBorder = border ?? Border.all(
      color: const Color(0xFF007AFF).withValues(alpha: isDark ? 0.25 : 0.12),
      width: 1.0,
    );

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: const Color(0xFF007AFF).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: defaultColor,
              borderRadius: br,
              border: defaultBorder,
              gradient: gradient,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class GlassCard extends StatefulWidget {
  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final GlassLevel level;
  final VoidCallback? onTap;
  final bool animateAppearance;
  final Color? accentColor;

  const GlassCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(20.0),
    this.margin,
    this.level = GlassLevel.level2,
    this.onTap,
    this.animateAppearance = true,
    this.accentColor,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    if (widget.animateAppearance) {
      _animController.forward();
    } else {
      _animController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blur = switch (widget.level) {
      GlassLevel.level1 => 12.0,
      GlassLevel.level2 => 20.0,
      GlassLevel.level3 => 30.0,
    };

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null || widget.trailing != null) ...[
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.title != null)
                      Text(
                        widget.title!,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1C1C1E)),
                      ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle!,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
          const SizedBox(height: 14),
        ],
        widget.child,
      ],
    );

    Widget card = GlassSurface(
      blur: blur,
      padding: widget.padding,
      margin: widget.margin,
      child: content,
    );

    if (widget.onTap != null) {
      card = InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: widget.onTap,
        child: card,
      );
    }

    if (!widget.animateAppearance) return card;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(position: _slideAnim, child: card),
    );
  }
}

class GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isSecondary;
  final Color? color;

  const GlassButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isSecondary = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isSecondary
        ? const Color(0xFFF2F2F7)
        : (color ?? const Color(0xFF007AFF));
    final fg = isSecondary ? const Color(0xFF1C1C1E) : Colors.white;

    return SizedBox(
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: isSecondary ? 0 : 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: -0.2)),
                ],
              ),
      ),
    );
  }
}

class AmbientBackground extends StatelessWidget {
  final Widget child;
  final Color primaryGlow;
  final Color secondaryGlow;

  const AmbientBackground({
    super.key,
    required this.child,
    this.primaryGlow = const Color(0xFF007AFF),
    this.secondaryGlow = const Color(0xFF5856D6),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryGlow.withValues(alpha: 0.08),
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          left: -60,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: secondaryGlow.withValues(alpha: 0.06),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
