import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../api_client.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

/// Premium Apple 'Hello'-style intro: Single-line signature reveal with soft-feathered light curtain.
///
/// Timeline (5800ms total):
///  0–500ms   Soft ambient dark warm amber sunrise glow background
///  500–2800ms "Hemapriyan" draws continuously on a single line (Pinyon Script)
///              H: deliberate sweeping loops (500–1600ms)
///              emapriyan: smooth organic flow (1600–2800ms)
///  2800–3500ms Luminous soft white shimmer sweeps across completed signature
///  3500–4100ms Hold — clean, sharp, perfectly centered signature
///  4100–4800ms Smooth crossfade amber → neutral theme
///  4800–5800ms QenBel × MyHarur brand reveal
class IntroAnimationScreen extends ConsumerStatefulWidget {
  const IntroAnimationScreen({super.key});

  @override
  ConsumerState<IntroAnimationScreen> createState() =>
      _IntroAnimationScreenState();
}

class _IntroAnimationScreenState extends ConsumerState<IntroAnimationScreen>
    with TickerProviderStateMixin {

  late final AnimationController _master;

  // Background sunrise glow shift
  late final Animation<double> _bgFadeIn;
  late final Animation<double> _bgShift;

  // Signature reveal progress (0→1)
  late final Animation<double> _sigReveal;

  // Pen tip & light veil intensity
  late final Animation<double> _penGlow;

  // Post-completion shimmer sweep
  late final Animation<double> _shimmer;

  // Hold opacity for signature
  late final Animation<double> _signatureOpacity;

  // Crossfade amber → neutral
  late final Animation<double> _crossfade;

  // Act 3 brand reveal
  late final Animation<double> _act3Fade;
  late final Animation<double> _qenbelScale;
  late final Animation<double> _qenbelFade;
  late final Animation<double> _dividerFade;
  late final Animation<double> _myharurFade;
  late final Animation<double> _myharurSlide;
  late final Animation<double> _taglineFade;

  // Exit transition
  late final Animation<double> _contentOpacity;

  // Parallel boot tracker
  String? _pendingRoute;
  bool _animDone = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5800),
    );

    // Background sunrise: 0–500ms
    _bgFadeIn = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.0, 0.086, curve: Curves.easeOut),
    );
    _bgShift = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.0, 0.70, curve: Curves.easeInOut),
    );

    // Signature draw: 500ms → 2800ms (0.086 → 0.483)
    _sigReveal = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.086, 0.483, curve: _SignatureCurve()),
    );

    // Light veil & pen glow intensity
    _penGlow = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 12,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 18,
      ),
    ]).animate(CurvedAnimation(
      parent: _master,
      curve: const Interval(0.086, 0.483),
    ));

    // Shimmer sweep: 2800ms → 3500ms (0.483 → 0.603)
    _shimmer = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.483, 0.603, curve: Curves.easeInOut),
    );

    // Signature stays visible during shimmer + hold (500ms → 4100ms)
    _signatureOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 10,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 75),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
    ]).animate(CurvedAnimation(
      parent: _master,
      curve: const Interval(0.086, 0.707),
    ));

    // Crossfade: 4100ms → 4800ms (0.707 → 0.828)
    _crossfade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.707, 0.828, curve: Curves.easeInOut),
    );

    // Act 3 QenBel branding: 4800ms → 5800ms
    _act3Fade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.810, 0.880, curve: Curves.easeOut),
    );
    _qenbelFade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.810, 0.890, curve: Curves.easeOut),
    );
    _qenbelScale = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.810, 0.910, curve: Curves.easeOutCubic),
      ),
    );
    _dividerFade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.880, 0.930, curve: Curves.easeOut),
    );
    _myharurFade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.900, 0.950, curve: Curves.easeOut),
    );
    _myharurSlide = Tween<double>(begin: 12.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.900, 0.960, curve: Curves.easeOutCubic),
      ),
    );
    _taglineFade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.940, 0.985, curve: Curves.easeOut),
    );

    _contentOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.980, 1.0, curve: Curves.easeIn),
      ),
    );

    _master.forward().then((_) => _onAnimDone());
    _runBoot();
  }

  Future<void> _runBoot() async {
    try { await ApiClient.dio.get('/config/'); } catch (_) {}
    await ref.read(authProvider.notifier).tryAutoLogin();
    final auth = ref.read(authProvider);

    String route;
    if (!auth.isLoggedIn)           route = '/login';
    else if (auth.usernameRequired)  route = '/username-setup';
    else if (!auth.isSetupComplete)  route = '/onboarding';
    else                             route = '/home';

    _pendingRoute = route;
    if (_animDone && mounted) _navigate(route);
  }

  void _onAnimDone() {
    _animDone = true;
    if (_pendingRoute != null && mounted) _navigate(_pendingRoute!);
  }

  void _navigate(String route) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (mounted) context.go(route);
  }

  @override
  void dispose() {
    _master.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = ref.watch(themeProvider) == ThemeMode.dark;
    final size    = MediaQuery.of(context).size;
    final neutral = isDark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: neutral,
      body: AnimatedBuilder(
        animation: _master,
        builder: (context, _) {
          final crossV = _crossfade.value;
          return Opacity(
            opacity: _contentOpacity.value,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Ambient animated warm amber sunrise background ────────────
                Opacity(
                  opacity: _bgFadeIn.value * (1.0 - crossV),
                  child: _AmberBackground(shiftProgress: _bgShift.value),
                ),

                // ── Neutral background (crossfade target) ─────────────────────
                Opacity(opacity: crossV, child: ColoredBox(color: neutral)),

                // ── Single-Line Signature Act 1 ────────────────────────────────
                Opacity(
                  opacity: _signatureOpacity.value * (1.0 - crossV),
                  child: Center(
                    child: SizedBox(
                      width: size.width,
                      height: 200,
                      child: CustomPaint(
                        painter: _SoftVeilSignaturePainter(
                          revealProgress: _sigReveal.value,
                          penGlowOpacity: _penGlow.value,
                          shimmerProgress: _shimmer.value,
                          containerWidth: size.width,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Act 3: QenBel Brand Reveal ────────────────────────────────
                Opacity(
                  opacity: _act3Fade.value,
                  child: _Act3Brand(
                    isDark: isDark,
                    screenWidth: size.width,
                    qenbelFade: _qenbelFade.value,
                    qenbelScale: _qenbelScale.value,
                    dividerFade: _dividerFade.value,
                    myharurFade: _myharurFade.value,
                    myharurSlide: _myharurSlide.value,
                    taglineFade: _taglineFade.value,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Custom Apple Signature Easing Curve ───────────────────────────────────────
class _SignatureCurve extends Curve {
  const _SignatureCurve();
  @override
  double transformInternal(double t) {
    // H takes 32% of time for elaborate loops (28% of path)
    if (t < 0.32) {
      final u = t / 0.32;
      return (u * u * u) * 0.28;
    }
    // emapriyan: smooth flowing ease-in-out
    final u = (t - 0.32) / 0.68;
    return 0.28 + Curves.easeInOutCubic.transform(u) * 0.72;
  }
}

// ─── Soft-Feathered Light Veil Signature Painter ──────────────────────────────
class _SoftVeilSignaturePainter extends CustomPainter {
  final double revealProgress;
  final double penGlowOpacity;
  final double shimmerProgress;
  final double containerWidth;

  const _SoftVeilSignaturePainter({
    required this.revealProgress,
    required this.penGlowOpacity,
    required this.shimmerProgress,
    required this.containerWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (revealProgress <= 0.0) return;

    // Dynamically calculate font size so "Hemapriyan" ALWAYS fits on a SINGLE line!
    // Never wrap text under any viewport dimension.
    final targetWidth = containerWidth * 0.82;
    double fontSize = (targetWidth / 4.4).clamp(36.0, 92.0);

    final style = TextStyle(
      fontFamily: 'PinyonScript',
      fontSize: fontSize,
      color: Colors.white,
      letterSpacing: 1.2,
      height: 1.0,
    );

    // Layout TextPainter without maxWidth to PREVENT WRAPPING
    final tp = TextPainter(
      text: TextSpan(text: 'Hemapriyan', style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    // Scale down if still slightly larger than available width
    double scale = 1.0;
    if (tp.width > containerWidth * 0.88) {
      scale = (containerWidth * 0.88) / tp.width;
    }

    final textWidth  = tp.width * scale;
    final textHeight = tp.height * scale;
    final textX      = (size.width - textWidth) / 2;
    final textY      = (size.height - textHeight) / 2;

    final revealX = textX + (textWidth * revealProgress.clamp(0.0, 1.0));

    canvas.save();
    if (scale != 1.0) {
      canvas.translate(textX, textY);
      canvas.scale(scale);
      canvas.translate(-textX / scale, -textY / scale);
    }

    // ── 1. Soft Feathered Light Veil Mask Reveal ──────────────────────────────
    // Replace hard clip box with a soft-edged alpha gradient layer
    final maskRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.saveLayer(maskRect, Paint());

    // Paint the full text painter
    tp.paint(canvas, Offset(textX, textY));

    // Feathered gradient mask to reveal text up to revealX with soft leading edge
    const featherWidth = 36.0; // 36px soft feather transition
    final maskPaint = Paint()
      ..blendMode = BlendMode.dstIn
      ..shader = LinearGradient(
        colors: const [
          Color(0xFFFFFFFF), // fully revealed
          Color(0xFFFFFFFF),
          Color(0x99FFFFFF), // soft feathering
          Color(0x00FFFFFF), // unrevealed transparent
        ],
        stops: [
          0.0,
          ((revealX - textX - featherWidth) / size.width).clamp(0.0, 1.0),
          ((revealX - textX) / size.width).clamp(0.0, 1.0),
          ((revealX - textX + featherWidth) / size.width).clamp(0.0, 1.0),
        ],
      ).createShader(maskRect);

    canvas.drawRect(maskRect, maskPaint);
    canvas.restore(); // Restore mask layer

    // ── 2. Glowing Light Veil Beam & Cursor Tip ────────────────────────────────
    if (penGlowOpacity > 0.01 && revealProgress < 0.995) {
      final gy = textY + textHeight * 0.56;

      // Soft vertical light curtain beam behind cursor
      final beamRect = Rect.fromLTWH(
        revealX - 16,
        textY - 20,
        32,
        textHeight + 40,
      );
      final beamPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.white.withOpacity(0.18 * penGlowOpacity),
            const Color(0xFFFFC060).withOpacity(0.35 * penGlowOpacity),
            Colors.white.withOpacity(0.18 * penGlowOpacity),
            Colors.transparent,
          ],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        ).createShader(beamRect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawRect(beamRect, beamPaint);

      // Radial light bloom tip
      canvas.drawCircle(
        Offset(revealX, gy),
        28,
        Paint()
          ..color = const Color(0xFFE8820A).withOpacity(0.26 * penGlowOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
      );
      canvas.drawCircle(
        Offset(revealX, gy),
        12,
        Paint()
          ..color = Colors.white.withOpacity(0.65 * penGlowOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(
        Offset(revealX, gy),
        3.0,
        Paint()..color = Colors.white.withOpacity(0.95 * penGlowOpacity),
      );
    }

    // ── 3. Luminous Shimmer Sweep Post-Completion ─────────────────────────────
    if (shimmerProgress > 0.01) {
      final shimX = textX + (textWidth * shimmerProgress);
      final shimW = textWidth * 0.22;
      final shimRect = Rect.fromCenter(
        center: Offset(shimX, textY + textHeight / 2),
        width: shimW,
        height: textHeight * 1.3,
      );

      canvas.saveLayer(Rect.fromLTWH(textX, textY - 10, textWidth, textHeight + 20), Paint());
      tp.paint(canvas, Offset(textX, textY));

      canvas.drawRect(
        shimRect,
        Paint()
          ..blendMode = BlendMode.srcIn
          ..shader = LinearGradient(
            colors: [
              Colors.transparent,
              Colors.white.withOpacity(0.20),
              Colors.white.withOpacity(0.45),
              Colors.white.withOpacity(0.20),
              Colors.transparent,
            ],
            stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
          ).createShader(shimRect),
      );
      canvas.restore();
    }

    canvas.restore(); // Restore scale
  }

  @override
  bool shouldRepaint(_SoftVeilSignaturePainter old) =>
      old.revealProgress != revealProgress ||
      old.penGlowOpacity != penGlowOpacity ||
      old.shimmerProgress != shimmerProgress ||
      old.containerWidth != containerWidth;
}

// ─── Warm Orange-to-Dark-Brown Sunrise Gradient ───────────────────────────────
class _AmberBackground extends StatelessWidget {
  final double shiftProgress;
  const _AmberBackground({required this.shiftProgress});

  @override
  Widget build(BuildContext context) {
    // Subtle cinematic movement: warm amber light slowly shifting from left to right
    final cx = -0.22 + (shiftProgress * 0.44);
    final cy = -0.18 + (math.sin(shiftProgress * math.pi) * 0.06);

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(cx, cy),
          radius: 1.50,
          colors: const [
            Color(0xFFF28C0F), // golden amber highlight
            Color(0xFFD46800), // warm amber mid
            Color(0xFF8B3A00), // deep warm brown
            Color(0xFF3D1200), // rich dark brown
            Color(0xFF140400), // near black atmospheric shadow
          ],
          stops: const [0.0, 0.22, 0.45, 0.70, 1.0],
        ),
      ),
    );
  }
}

// ─── Act 3 Brand Reveal (QenBel × MyHarur) ────────────────────────────────────
class _Act3Brand extends StatelessWidget {
  final bool isDark;
  final double screenWidth;
  final double qenbelFade, qenbelScale, dividerFade;
  final double myharurFade, myharurSlide, taglineFade;

  const _Act3Brand({
    required this.isDark,
    required this.screenWidth,
    required this.qenbelFade,
    required this.qenbelScale,
    required this.dividerFade,
    required this.myharurFade,
    required this.myharurSlide,
    required this.taglineFade,
  });

  @override
  Widget build(BuildContext context) {
    final fg     = isDark ? Colors.white : Colors.black;
    final subtle = fg.withOpacity(0.32);
    final div    = fg.withOpacity(0.10);

    return Center(
      child: SizedBox(
        width: screenWidth * 0.78,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // QenBel logo
            Opacity(
              opacity: qenbelFade,
              child: Transform.scale(
                scale: qenbelScale,
                child: Image.asset(
                  isDark ? 'assets/qenbel_dark.png' : 'assets/qenbel_light.png',
                  width: screenWidth * 0.50,
                  height: 50,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 26),
            // Thin divider
            Opacity(
              opacity: dividerFade,
              child: Container(width: 28, height: 1, color: div),
            ),
            const SizedBox(height: 22),
            // MyHarur wordmark
            Opacity(
              opacity: myharurFade,
              child: Transform.translate(
                offset: Offset(0, myharurSlide),
                child: Text(
                  'MyHarur',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -2.0,
                    color: fg,
                    height: 1.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Tagline
            Opacity(
              opacity: taglineFade,
              child: Text(
                'A QenBel Technologies Product',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.4,
                  color: subtle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
