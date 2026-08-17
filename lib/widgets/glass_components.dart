import 'dart:ui';
import 'package:flutter/material.dart';

enum GlassLevel { level1, level2, level3 }
enum BentoCardVariant { pastel, darkPetrol, elevatedWhite }

/// Atmospheric Ambient Background with organic blurred aurora glowing mesh
/// Matches the modern Scandinavian / Neo-minimalist visual aesthetic.
class AtmosphericBackground extends StatelessWidget {
  final Widget child;
  final Color primaryBlob;
  final Color secondaryBlob;
  final Color baseColor;

  const AtmosphericBackground({
    super.key,
    required this.child,
    this.primaryBlob = const Color(0xFF234149),
    this.secondaryBlob = const Color(0xFF8EB7C7),
    this.baseColor = const Color(0xFFF6F9FA),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: baseColor,
      child: Stack(
        children: [
          // Top right ambient dark-slate aurora blob
          Positioned(
            top: -60,
            right: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 75, sigmaY: 75),
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryBlob.withValues(alpha: 0.18),
                ),
              ),
            ),
          ),
          // Top left misty cyan aurora blob
          Positioned(
            top: 40,
            left: -60,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 65, sigmaY: 65),
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: secondaryBlob.withValues(alpha: 0.22),
                ),
              ),
            ),
          ),
          // Bottom right subtle ambient glow
          Positioned(
            bottom: 80,
            right: -40,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: secondaryBlob.withValues(alpha: 0.14),
                ),
              ),
            ),
          ),
          // Main screen content
          child,
        ],
      ),
    );
  }
}

/// Bento Card Component for Asymmetric Grid Layouts
class BentoCard extends StatelessWidget {
  final Widget child;
  final BentoCardVariant variant;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final double? height;
  final double? width;

  const BentoCard({
    super.key,
    required this.child,
    this.variant = BentoCardVariant.pastel,
    this.padding = const EdgeInsets.all(18.0),
    this.margin,
    this.borderRadius = 24.0,
    this.onTap,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Border border;
    List<BoxShadow> shadows;

    switch (variant) {
      case BentoCardVariant.darkPetrol:
        bg = const Color(0xFF234149);
        border = Border.all(color: const Color(0xFF355E69), width: 1.2);
        shadows = [
          BoxShadow(
            color: const Color(0xFF234149).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ];
        break;
      case BentoCardVariant.pastel:
        bg = const Color(0xFFE2EDF2);
        border = Border.all(color: const Color(0xFFD4E3EA), width: 1.0);
        shadows = [
          BoxShadow(
            color: const Color(0xFF234149).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ];
        break;
      case BentoCardVariant.elevatedWhite:
        bg = Colors.white;
        border = Border.all(color: const Color(0xFFE3EDF2), width: 1.2);
        shadows = [
          BoxShadow(
            color: const Color(0xFF234149).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ];
        break;
    }

    Widget content = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}

/// Squircle Action Tile (used in Screen 3 header row)
class SquircleTile extends StatelessWidget {
  final Widget icon;
  final String label;
  final String? sublabel;
  final bool isSelected;
  final VoidCallback? onTap;

  const SquircleTile({
    super.key,
    required this.icon,
    required this.label,
    this.sublabel,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : const Color(0xFFE2EDF2),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected ? const Color(0xFF234149).withValues(alpha: 0.2) : const Color(0xFFD4E3EA),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF234149).withValues(alpha: 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  color: isSelected ? const Color(0xFF16272E) : const Color(0xFF4A626B),
                  letterSpacing: -0.2,
                ),
              ),
              if (sublabel != null) ...[
                const SizedBox(height: 2),
                Text(
                  sublabel!,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9, color: Color(0xFF7A939C), fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width Squircle Button in Deep Slate Petrol (#234149)
class PetrolButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final VoidCallback? onTap;
  final dynamic icon; // Widget or IconData
  final bool isLoading;
  final bool isSecondary;
  final Color? color;
  final double height;
  final double borderRadius;

  const PetrolButton({
    super.key,
    required this.label,
    this.onPressed,
    this.onTap,
    this.icon,
    this.isLoading = false,
    this.isSecondary = false,
    this.color,
    this.height = 54,
    this.borderRadius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isSecondary
        ? const Color(0xFFE2EDF2)
        : (color ?? const Color(0xFF234149));
    final fg = isSecondary ? const Color(0xFF16272E) : Colors.white;

    Widget? iconWidget;
    if (icon is Widget) {
      iconWidget = icon as Widget;
    } else if (icon is IconData) {
      iconWidget = Icon(icon as IconData, size: 20, color: fg);
    }

    final callback = onPressed ?? onTap;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: isSecondary ? 0 : 4,
          shadowColor: const Color(0xFF234149).withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        onPressed: isLoading ? null : callback,
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
                  if (iconWidget != null) ...[iconWidget, const SizedBox(width: 8)],
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: -0.2,
                      color: fg,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Clean Minimalist Pill Input Container
class SquirclePillInput extends StatelessWidget {
  final Widget? child;
  final TextEditingController? controller;
  final String? hint;
  final IconData? icon;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const SquirclePillInput({
    super.key,
    this.child,
    this.controller,
    this.hint,
    this.icon,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (child != null) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F7F9),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: const Color(0xFFDCE7EC), width: 1.2),
        ),
        child: child,
      );
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F9),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFFDCE7EC), width: 1.2),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: const Color(0xFF234149)),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF16272E)),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFF8BA6B0), fontSize: 13, fontWeight: FontWeight.w600),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (suffix != null) suffix!,
        ],
      ),
    );
  }
}

/// GlassSurface with modernized frosted aesthetic
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
    this.opacity = 0.88,
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
    final br = borderRadius ?? BorderRadius.circular(24);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultColor = color ?? (isDark ? const Color(0xFF16272E) : Colors.white).withValues(alpha: opacity);
    final defaultBorder = border ?? Border.all(
      color: const Color(0xFF234149).withValues(alpha: isDark ? 0.25 : 0.10),
      width: 1.0,
    );

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: const Color(0xFF234149).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 5),
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
    this.padding = const EdgeInsets.all(18.0),
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
      duration: const Duration(milliseconds: 360),
    );

    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
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
      GlassLevel.level1 => 10.0,
      GlassLevel.level2 => 18.0,
      GlassLevel.level3 => 28.0,
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
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF16272E), letterSpacing: -0.3),
                      ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle!,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6A828B), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
          const SizedBox(height: 12),
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
        borderRadius: BorderRadius.circular(24),
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
    return PetrolButton(
      label: label,
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: 18) : null,
      isLoading: isLoading,
      isSecondary: isSecondary,
      color: color,
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
    this.primaryGlow = const Color(0xFF234149),
    this.secondaryGlow = const Color(0xFF8EB7C7),
  });

  @override
  Widget build(BuildContext context) {
    return AtmosphericBackground(
      primaryBlob: primaryGlow,
      secondaryBlob: secondaryGlow,
      child: child,
    );
  }
}
