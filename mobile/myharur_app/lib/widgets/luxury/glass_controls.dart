import 'package:flutter/material.dart';
import '../../theme/luxury_theme.dart';
import 'glass_surface.dart';

/// 1. Glass Slider
class GlassSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final String? label;

  const GlassSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label!, style: LuxuryTypography.secondary),
              Text(
                '${(value * 100).toInt()}%',
                style: LuxuryTypography.secondary.copyWith(
                  color: LuxuryColors.alabasterGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6,
            activeTrackColor: LuxuryColors.racingRed,
            inactiveTrackColor: Colors.white.withOpacity(0.12),
            thumbColor: LuxuryColors.alabasterGrey,
            overlayColor: LuxuryColors.redGlow.withOpacity(0.3),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

/// 2. Glass Toggle Switch
class GlassToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  const GlassToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: LuxuryTypography.body),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 52,
              height: 30,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: value
                    ? LuxuryColors.racingRed.withOpacity(0.85)
                    : Colors.white.withOpacity(0.10),
                border: Border.all(
                  color: value
                      ? LuxuryColors.racingRed
                      : Colors.white.withOpacity(0.18),
                ),
                boxShadow: value
                    ? [
                        BoxShadow(
                          color: LuxuryColors.redGlow.withOpacity(0.4),
                          blurRadius: 12,
                        ),
                      ]
                    : [],
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: LuxuryColors.primaryText,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 3. Glass Text Input Field
class GlassTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final String? label;
  final IconData? prefixIcon;
  final bool obscureText;
  final ValueChanged<String>? onChanged;

  const GlassTextField({
    super.key,
    this.controller,
    required this.hintText,
    this.label,
    this.prefixIcon,
    this.obscureText = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: LuxuryTypography.secondary),
          const SizedBox(height: 6),
        ],
        GlassSurface(
          level: GlassLevel.level1,
          borderRadius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            onChanged: onChanged,
            style: LuxuryTypography.body,
            cursorColor: LuxuryColors.racingRed,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: LuxuryTypography.secondary,
              border: InputBorder.none,
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: LuxuryColors.secondaryText, size: 20)
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

/// 4. Glass Progress Bar
class GlassProgress extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final Color progressColor;
  final bool showGlowingEdge;

  const GlassProgress({
    super.key,
    required this.progress,
    this.progressColor = const Color(0xFF00E5FF),
    this.showGlowingEdge = true,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final filledWidth = width * clamped;

        return Container(
          height: 8,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.white.withOpacity(0.10),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Progress Fill
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: filledWidth,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    colors: [
                      progressColor.withOpacity(0.6),
                      progressColor,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: progressColor.withOpacity(0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),

              // Glowing Leading Edge
              if (showGlowingEdge && filledWidth > 8)
                Positioned(
                  left: filledWidth - 8,
                  top: 0,
                  bottom: 0,
                  width: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: progressColor,
                          blurRadius: 10,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
