import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/luxury_theme.dart';

enum GlassLevel { level1, level2, level3, redGlass }

class GlassSurface extends StatefulWidget {
  final Widget child;
  final GlassLevel level;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool enableReflection;
  final bool performanceMode;
  final bool showRedGlow;

  const GlassSurface({
    super.key,
    required this.child,
    this.level = GlassLevel.level2,
    this.borderRadius = LuxuryShapes.cardRadius,
    this.padding,
    this.margin,
    this.onTap,
    this.enableReflection = false,
    this.performanceMode = false,
    this.showRedGlow = false,
  });

  @override
  State<GlassSurface> createState() => _GlassSurfaceState();
}

class _GlassSurfaceState extends State<GlassSurface>
    with SingleTickerProviderStateMixin {
  AnimationController? _reflectionController;

  @override
  void initState() {
    super.initState();
    if (widget.enableReflection) {
      _reflectionController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 5),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _reflectionController?.dispose();
    super.dispose();
  }

  double get _blurSigma {
    if (widget.performanceMode) return 10.0;
    switch (widget.level) {
      case GlassLevel.level1:
        return 20.0;
      case GlassLevel.level2:
        return 28.0;
      case GlassLevel.level3:
        return 35.0;
      case GlassLevel.redGlass:
        return 24.0;
    }
  }

  Color get _backgroundColor {
    switch (widget.level) {
      case GlassLevel.level1:
        return LuxuryColors.glassLevel1;
      case GlassLevel.level2:
        return LuxuryColors.glassLevel2;
      case GlassLevel.level3:
        return LuxuryColors.glassLevel3;
      case GlassLevel.redGlass:
        return LuxuryColors.redGlass;
    }
  }

  Color get _borderColor {
    switch (widget.level) {
      case GlassLevel.redGlass:
        return LuxuryColors.racingRed.withOpacity(0.30);
      case GlassLevel.level3:
        return LuxuryColors.glassBorder;
      case GlassLevel.level2:
        return LuxuryColors.glassWhiteStrong.withOpacity(0.18);
      case GlassLevel.level1:
        return LuxuryColors.glassBorderSoft;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget surface = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(color: _borderColor, width: 1.2),
            boxShadow: [
              if (widget.showRedGlow || widget.level == GlassLevel.redGlass)
                BoxShadow(
                  color: LuxuryColors.racingRed.withOpacity(0.35),
                  blurRadius: 28,
                  spreadRadius: 2,
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 22,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Stack(
            children: [
              // Specular Top Rim Reflection Line (High-Isomorphism Detail)
              Positioned(
                top: 0,
                left: 16,
                right: 16,
                height: 1.5,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.40),
                        LuxuryColors.champagneGold.withOpacity(0.35),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4, 0.7, 1.0],
                    ),
                  ),
                ),
              ),

              // Traveling Specular Reflection (4-7s sweep)
              if (widget.enableReflection && _reflectionController != null)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _reflectionController!,
                    builder: (context, _) {
                      final val = _reflectionController!.value;
                      return IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(-2.0 + (val * 4.0), -1.0),
                              end: Alignment(-1.0 + (val * 4.0), 1.0),
                              colors: [
                                Colors.transparent,
                                Colors.white.withOpacity(0.08),
                                LuxuryColors.champagneGold.withOpacity(0.06),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.4, 0.7, 1.0],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              widget.child,
            ],
          ),
        ),
      ),
    );

    if (widget.margin != null) {
      surface = Padding(padding: widget.margin!, child: surface);
    }

    if (widget.onTap != null) {
      surface = GestureDetector(
        onTap: widget.onTap,
        child: surface,
      );
    }

    return surface;
  }
}
