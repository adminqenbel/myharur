import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/luxury_theme.dart';
import 'glass_surface.dart';
import 'glass_button.dart';
import 'glass_controls.dart';

enum DownloadState { idle, downloading, completed }

class DownloadAnimationWidget extends StatefulWidget {
  final double durationSeconds;
  final VoidCallback? onCompleted;

  const DownloadAnimationWidget({
    super.key,
    this.durationSeconds = 8.0,
    this.onCompleted,
  });

  @override
  State<DownloadAnimationWidget> createState() => _DownloadAnimationWidgetState();
}

class _DownloadAnimationWidgetState extends State<DownloadAnimationWidget>
    with TickerProviderStateMixin {
  DownloadState _state = DownloadState.idle;
  double _progress = 0.0;
  Timer? _timer;

  // Animations
  late final AnimationController _pulseController;
  late final AnimationController _completionController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _completionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _completionController.dispose();
    super.dispose();
  }

  void _startDownload() {
    setState(() {
      _state = DownloadState.downloading;
      _progress = 0.0;
    });

    final intervalMs = 50;
    final totalSteps = (widget.durationSeconds * 1000) / intervalMs;
    final stepIncrement = 1.0 / totalSteps;

    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (!mounted) return;
      setState(() {
        _progress += stepIncrement;
        if (_progress >= 1.0) {
          _progress = 1.0;
          _state = DownloadState.completed;
          _timer?.cancel();
          _completionController.forward(from: 0.0);
          if (widget.onCompleted != null) widget.onCompleted!();
        }
      });
    });
  }

  void _cancelDownload() {
    _timer?.cancel();
    setState(() {
      _state = DownloadState.idle;
      _progress = 0.0;
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _state = DownloadState.idle;
      _progress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      level: GlassLevel.level3,
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      enableReflection: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header / Central Glowing Diamond & Parachute Download Symbol
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              final pulse = _pulseController.value;
              final scale = _state == DownloadState.downloading
                  ? 1.0 + (pulse * 0.06)
                  : 1.0;

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                    border: Border.all(
                      color: _state == DownloadState.completed
                          ? LuxuryColors.racingRed
                          : const Color(0xFF00E5FF).withOpacity(0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _state == DownloadState.completed
                            ? LuxuryColors.redGlow
                            : const Color(0xFF00E5FF).withOpacity(0.35 + (pulse * 0.2)),
                        blurRadius: 25,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _state == DownloadState.completed
                        ? const Icon(
                            Icons.check_rounded,
                            size: 44,
                            color: LuxuryColors.primaryText,
                          )
                        : CustomPaint(
                            size: const Size(44, 44),
                            painter: DiamondParachuteIconPainter(
                              glowColor: const Color(0xFF00E5FF),
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Idle State
          if (_state == DownloadState.idle) ...[
            Text('Download Center', style: LuxuryTypography.cardTitle),
            const SizedBox(height: 6),
            Text('paradrop-kit.txt • 7 KB', style: LuxuryTypography.secondary),
            const SizedBox(height: 20),
            GlassButton(
              text: 'START DOWNLOAD',
              variant: GlassButtonVariant.primaryRed,
              onPressed: _startDownload,
            ),
          ],

          // Downloading State
          if (_state == DownloadState.downloading) ...[
            Text(
              '${(_progress * 100).toInt()}%',
              style: LuxuryTypography.heroTitle.copyWith(
                color: const Color(0xFF00E5FF),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            GlassProgress(
              progress: _progress,
              progressColor: const Color(0xFF00E5FF),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'paradrop-kit.txt',
                  style: LuxuryTypography.secondary.copyWith(
                    fontFamily: 'monospace',
                    color: LuxuryColors.alabasterGrey,
                  ),
                ),
                Text('7 KB', style: LuxuryTypography.secondary),
              ],
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: _cancelDownload,
              child: Text(
                'CANCEL',
                style: LuxuryTypography.buttonText.copyWith(
                  fontSize: 13,
                  color: LuxuryColors.racingRed,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],

          // Completed State
          if (_state == DownloadState.completed) ...[
            Text(
              'Download Complete',
              style: LuxuryTypography.cardTitle.copyWith(
                color: LuxuryColors.alabasterGrey,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'paradrop-kit.txt • 7 KB',
              style: LuxuryTypography.secondary.copyWith(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GlassButton(
                    text: 'RESET',
                    variant: GlassButtonVariant.outlineGlass,
                    onPressed: _reset,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassButton(
                    text: 'OPEN FILE',
                    variant: GlassButtonVariant.primaryRed,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Custom painter for Diamond / Parachute download symbol
class DiamondParachuteIconPainter extends CustomPainter {
  final Color glowColor;

  const DiamondParachuteIconPainter({required this.glowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = glowColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Diamond path
    final diamond = Path()
      ..moveTo(cx, cy - 18)
      ..lineTo(cx + 14, cy - 4)
      ..lineTo(cx, cy + 14)
      ..lineTo(cx - 14, cy - 4)
      ..close();

    canvas.drawPath(diamond, fillPaint);
    canvas.drawPath(diamond, strokePaint);

    // Arrow down
    final arrow = Path()
      ..moveTo(cx, cy - 6)
      ..lineTo(cx, cy + 6)
      ..moveTo(cx - 5, cy + 2)
      ..lineTo(cx, cy + 7)
      ..lineTo(cx + 5, cy + 2);

    canvas.drawPath(arrow, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
