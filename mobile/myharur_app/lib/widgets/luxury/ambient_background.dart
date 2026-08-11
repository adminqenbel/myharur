import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/luxury_theme.dart';

/// Dynamic ambient background featuring living, continuous Gemini light motion
class AmbientBackground extends StatefulWidget {
  final Widget child;
  final bool performanceMode;
  final bool reducedMotion;

  const AmbientBackground({
    super.key,
    required this.child,
    this.performanceMode = false,
    this.reducedMotion = false,
  });

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motionController;

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    );

    if (!widget.reducedMotion) {
      _motionController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AmbientBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reducedMotion != oldWidget.reducedMotion) {
      if (widget.reducedMotion) {
        _motionController.stop();
      } else {
        _motionController.repeat();
      }
    }
  }

  @override
  void dispose() {
    _motionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _motionController,
      builder: (context, _) {
        final t = _motionController.value;
        final rad = t * math.pi * 2;

        // Vivid wide-orbit Lissajous paths for high motion visibility
        final redX = math.sin(rad) * 160.0;
        final redY = math.cos(rad * 0.7) * 110.0;

        final goldX = math.cos(rad * 1.1) * 180.0;
        final goldY = math.sin(rad * 0.8) * 130.0;

        final centerCoreX = math.sin(rad * 1.4) * 130.0;
        final centerCoreY = math.cos(rad * 1.2) * 160.0;

        // Dynamic pulsing sizes & opacities
        final redScale = 1.0 + (math.sin(rad * 1.5) * 0.25);
        final goldScale = 1.0 + (math.cos(rad * 1.3) * 0.22);
        final redOpacity = 0.55 + (math.sin(rad * 2.0) * 0.15);
        final goldOpacity = 0.50 + (math.cos(rad * 1.8) * 0.15);

        return Stack(
          fit: StackFit.expand,
          children: [
            // Deep obsidian background base
            const ColoredBox(color: LuxuryColors.deepBackground),

            // 1. Top Crimson Red Living Glow Node (sweeping wide top canvas)
            Positioned(
              top: -120 + (widget.reducedMotion ? 0 : redY),
              left: -60 + (widget.reducedMotion ? 0 : redX),
              width: 480 * redScale,
              height: 480 * redScale,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      LuxuryColors.racingRed.withOpacity(widget.performanceMode ? 0.35 : redOpacity),
                      LuxuryColors.blackCherry.withOpacity(widget.performanceMode ? 0.20 : redOpacity * 0.65),
                      LuxuryColors.coffeeBean.withOpacity(0.12),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.40, 0.75, 1.0],
                  ),
                ),
              ),
            ),

            // 2. Bottom Champagne Gold Living Glow Node (sweeping bottom canvas)
            Positioned(
              bottom: -140 + (widget.reducedMotion ? 0 : goldY),
              right: -80 + (widget.reducedMotion ? 0 : goldX),
              width: 520 * goldScale,
              height: 520 * goldScale,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      LuxuryColors.champagneGold.withOpacity(widget.performanceMode ? 0.35 : goldOpacity),
                      LuxuryColors.silkSand.withOpacity(widget.performanceMode ? 0.20 : goldOpacity * 0.60),
                      LuxuryColors.goldGlow.withOpacity(0.15),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.35, 0.70, 1.0],
                  ),
                ),
              ),
            ),

            // 3. Mid-Canvas Floating Cherry/Coral Light Core (sweeping behind glass components)
            if (!widget.performanceMode)
              Positioned(
                top: 240 + (widget.reducedMotion ? 0 : centerCoreY),
                left: 40 + (widget.reducedMotion ? 0 : centerCoreX),
                width: 360,
                height: 360,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        LuxuryColors.cherryGlow.withOpacity(0.40 + math.sin(rad * 2.5) * 0.12),
                        LuxuryColors.redGlow.withOpacity(0.20),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.50, 1.0],
                    ),
                  ),
                ),
              ),

            // 4. Living Gemini Energy Stream Sweep
            if (!widget.performanceMode && !widget.reducedMotion)
              Positioned.fill(
                child: CustomPaint(
                  painter: GeminiEnergyStreamPainter(progress: t),
                ),
              ),

            // 5. Subtle Luxury Noise Overlay
            if (!widget.performanceMode)
              const Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: NoisePainter(),
                  ),
                ),
              ),

            // Main Screen Content
            widget.child,
          ],
        );
      },
    );
  }
}

/// Custom painter for living Gemini-style energy light stream passing diagonally
class GeminiEnergyStreamPainter extends CustomPainter {
  final double progress;

  const GeminiEnergyStreamPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final angle = progress * math.pi * 2;
    final startX = size.width * (0.1 + (math.sin(angle) * 0.35));
    final startY = size.height * (0.05 + (math.cos(angle * 0.8) * 0.25));
    final endX = size.width * (0.9 + (math.cos(angle) * 0.25));
    final endY = size.height * (0.95 + (math.sin(angle * 0.8) * 0.20));

    final sweepOpacity = 0.22 + (math.sin(angle * 2) * 0.08);

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          LuxuryColors.racingRed.withOpacity(0.0),
          LuxuryColors.racingRed.withOpacity(sweepOpacity),
          LuxuryColors.champagneGold.withOpacity(sweepOpacity * 1.2),
          LuxuryColors.champagneGold.withOpacity(0.0),
        ],
        stops: const [0.0, 0.35, 0.65, 1.0],
      ).createShader(Rect.fromLTRB(startX, startY, endX, endY))
      ..strokeWidth = 160.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70.0);

    final path = Path()
      ..moveTo(startX, startY)
      ..cubicTo(
        size.width * 0.6 + math.sin(angle * 1.2) * 90,
        size.height * 0.25,
        size.width * 0.3 + math.cos(angle * 1.2) * 90,
        size.height * 0.75,
        endX,
        endY,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant GeminiEnergyStreamPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Custom painter generating subtle luxury noise/grain
class NoisePainter extends CustomPainter {
  const NoisePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.018)
      ..strokeWidth = 1.0;

    final rand = math.Random(42);
    const count = 400;

    for (int i = 0; i < count; i++) {
      final dx = rand.nextDouble() * size.width;
      final dy = rand.nextDouble() * size.height;
      canvas.drawCircle(Offset(dx, dy), 0.7, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
