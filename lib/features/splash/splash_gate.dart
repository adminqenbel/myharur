import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/brand/logo_outline.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';

// ==============================================================================
// OPENING SEQUENCE (about 4.4 s, tap to skip)
//
//   Page 1  the MyHarur logo is DRAWN as vector lines (traced outline, blue-to-red stroke),
//           the full-colour illustration fades in as the lines settle, then "MyHarur" rises.
//   Page 2  "Developed and managed by" + the QenBel wordmark.
//   then    cross-fade into the app.
//
// The native Android splash is plain white, so the line drawing starts from a clean screen.
// The sequence waits for the saved session to restore (AuthService.ready) so a signed-in user goes
// straight to Home. Plays once per launch. Respects the system "remove animations" setting.
// ==============================================================================

const _kQenBelAsset = 'assets/brand/qenbel_wordmark.png';

/// Decodes the artwork before the first frame so nothing pops in.
Future<void> warmBrandLogo() async {
  await Future.wait([_warm(BrandLogo.asset), _warm(_kQenBelAsset)]);
}

Future<void> _warm(String asset) async {
  final done = Completer<void>();
  final stream = AssetImage(asset).resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (_, __) {
      if (!done.isCompleted) done.complete();
      stream.removeListener(listener);
    },
    onError: (_, __) {
      if (!done.isCompleted) done.complete();
    },
  );
  stream.addListener(listener);
  await done.future.timeout(const Duration(seconds: 2), onTimeout: () {});
}

class SplashGate extends StatefulWidget {
  final Widget child;

  /// Length of the whole sequence.
  final Duration duration;

  /// Upper bound on waiting for the saved session; after this the app opens anyway.
  final Duration maxWait;

  const SplashGate({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 4400),
    this.maxWait = const Duration(seconds: 4),
  });

  /// Test hook: makes the splash play again (it normally plays once per launch).
  @visibleForTesting
  static void debugReset() => _SplashGateState._playedThisLaunch = false;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> with SingleTickerProviderStateMixin {
  static bool _playedThisLaunch = false;

  late final AnimationController _c;
  bool _open = false;
  bool _started = false;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    // Created eagerly (not lazily) so dispose() is safe even when the splash is skipped.
    _c = AnimationController(vsync: this, duration: widget.duration);
    _open = _playedThisLaunch;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || _open) return;
    _started = true;

    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      _c.value = 0.86; // the finished "developed by" page, no motion
      Future<void>.delayed(const Duration(milliseconds: 900), _openWhenReady);
    } else {
      _c.forward().whenComplete(_openWhenReady);
    }
  }

  Future<void> _openWhenReady() async {
    if (_opening) return;
    _opening = true;
    await AuthService.ready.timeout(widget.maxWait, onTimeout: () {});
    if (!mounted) return;
    _playedThisLaunch = true;
    setState(() => _open = true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 520),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _open
          ? KeyedSubtree(key: const ValueKey('app'), child: widget.child)
          : GestureDetector(
              key: const ValueKey('splash'),
              behavior: HitTestBehavior.opaque,
              onTap: _openWhenReady, // tap to skip
              child: _Splash(animation: _c),
            ),
    );
  }
}

class _Splash extends StatelessWidget {
  final Animation<double> animation;
  const _Splash({required this.animation});

  static const double logoWidth = 196;
  static const double _logoHeight = logoWidth / BrandLogo.aspect;

  static double seg(double t, double from, double to, [Curve curve = Curves.easeOutCubic]) =>
      curve.transform(((t - from) / (to - from)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    // Material (not ColoredBox): supplies a proper DefaultTextStyle. Text outside any Material gets
    // Flutter's fallback style, which draws a yellow double underline.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark),
      child: Material(
        color: Colors.white,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final p = animation.value;

            // page 1
            final draw = seg(p, 0.02, 0.30, Curves.easeInOutCubic);
            final outlineAlpha = 1 - seg(p, 0.30, 0.46, Curves.easeIn);
            final fill = seg(p, 0.26, 0.46);
            final word = seg(p, 0.44, 0.58);
            final page1Out = 1 - seg(p, 0.66, 0.72, Curves.easeIn);

            // page 2
            final dev = seg(p, 0.72, 0.80);
            final qen = seg(p, 0.74, 0.86);

            return Stack(
              children: [
                Opacity(
                  opacity: page1Out,
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Transform.translate(
                          offset: const Offset(0, -26),
                          child: SizedBox(
                            width: logoWidth,
                            height: _logoHeight,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Opacity(opacity: fill, child: Transform.scale(scale: 0.96 + 0.04 * fill, child: const BrandLogo(width: logoWidth))),
                                CustomPaint(painter: _LineDrawPainter(progress: draw, alpha: outlineAlpha)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Transform.translate(
                          offset: Offset(0, _logoHeight / 2 + 22 + 14 * (1 - word)),
                          child: Opacity(opacity: word, child: Text(t.appName, style: AppTextStyles.largeTitle.copyWith(letterSpacing: -0.8))),
                        ),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(opacity: dev, child: Text(t.developedBy, style: AppTextStyles.subheadline.copyWith(color: AppColors.secondaryLabel))),
                      const SizedBox(height: 14),
                      Opacity(
                        opacity: qen,
                        child: Transform.scale(scale: 0.96 + 0.04 * qen, child: Image.asset(_kQenBelAsset, width: 170, semanticLabel: 'QenBel')),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Draws the traced logo outline progressively (a pen tracing the H, the tree and the palm).
class _LineDrawPainter extends CustomPainter {
  final double progress; // 0..1 how much of the line is drawn
  final double alpha; // 0..1 overall opacity of the stroke
  _LineDrawPainter({required this.progress, required this.alpha});

  static ui.Path? _cache;
  static Size? _cacheSize;

  static ui.Path _outline(Size size) {
    if (_cache != null && _cacheSize == size) return _cache!;
    final path = ui.Path();
    for (final poly in kLogoOutline) {
      for (var i = 0; i + 1 < poly.length; i += 2) {
        final x = poly[i] * size.width;
        final y = poly[i + 1] * size.height;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
    }
    _cache = path;
    _cacheSize = size;
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || alpha <= 0) return;
    final full = _outline(size);
    final metrics = full.computeMetrics().toList();
    final total = metrics.fold<double>(0, (a, m) => a + m.length);
    var remaining = total * progress;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, size.height),
        [AppColors.weatherBlue.withValues(alpha: alpha), AppColors.weatherViolet.withValues(alpha: alpha), AppColors.weatherRed.withValues(alpha: alpha)],
        const [0.0, 0.55, 1.0],
      );

    for (final m in metrics) {
      if (remaining <= 0) break;
      final len = remaining < m.length ? remaining : m.length;
      canvas.drawPath(m.extractPath(0, len), paint);
      remaining -= len;
    }
  }

  @override
  bool shouldRepaint(covariant _LineDrawPainter old) => old.progress != progress || old.alpha != alpha;
}
