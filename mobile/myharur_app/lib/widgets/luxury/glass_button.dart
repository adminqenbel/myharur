import 'package:flutter/material.dart';
import '../../theme/luxury_theme.dart';
import 'glass_surface.dart';

enum GlassButtonVariant { primaryRed, secondaryGlass, outlineGlass }

class GlassButton extends StatefulWidget {
  final String text;
  final Widget? icon;
  final VoidCallback? onPressed;
  final GlassButtonVariant variant;
  final bool isLoading;
  final double? width;
  final double height;

  const GlassButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.variant = GlassButtonVariant.primaryRed,
    this.isLoading = false,
    this.width,
    this.height = 54.0,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _scaleController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _scaleController.reverse();
    }
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Widget buttonContent = SizedBox(
      height: widget.height,
      width: widget.width,
      child: Center(
        child: widget.isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(LuxuryColors.primaryText),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    widget.icon!,
                    const SizedBox(width: 10),
                  ],
                  Text(
                    widget.text,
                    style: LuxuryTypography.buttonText.copyWith(
                      color: isEnabled
                          ? LuxuryColors.primaryText
                          : LuxuryColors.secondaryText.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
      ),
    );

    Widget decoratedButton;

    if (widget.variant == GlassButtonVariant.primaryRed) {
      decoratedButton = Container(
        decoration: BoxDecoration(
          color: LuxuryColors.racingRed.withOpacity(isEnabled ? 0.90 : 0.40),
          borderRadius: BorderRadius.circular(LuxuryShapes.buttonRadius),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: LuxuryColors.redGlow.withOpacity(0.45),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(LuxuryShapes.buttonRadius),
            onTap: isEnabled ? widget.onPressed : null,
            child: buttonContent,
          ),
        ),
      );
    } else if (widget.variant == GlassButtonVariant.outlineGlass) {
      decoratedButton = GlassSurface(
        level: GlassLevel.level1,
        borderRadius: LuxuryShapes.buttonRadius,
        onTap: isEnabled ? widget.onPressed : null,
        child: buttonContent,
      );
    } else {
      decoratedButton = GlassSurface(
        level: GlassLevel.level3,
        borderRadius: LuxuryShapes.buttonRadius,
        enableReflection: true,
        onTap: isEnabled ? widget.onPressed : null,
        child: buttonContent,
      );
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: decoratedButton,
      ),
    );
  }
}
