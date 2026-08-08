import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../api_client.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

/// Premium cinematic intro: Apple "Hello"-style signature reveal.
///
/// Timeline (5600ms total):
///  0–400ms   Dark → amber sunrise glow background
///  400–2600ms "Hemapriyan" draws stroke by stroke (Pinyon Script)
///              H: slow, deliberate loops (400–1500ms)
///              emapriyan: flowing, faster (1500–2600ms)
///  2600–3200ms Luminous shimmer sweeps left→right across complete signature
///  3200–3600ms Hold — clean, sharp, perfectly centred
///  3600–4300ms Crossfade amber → neutral
///  4300–5600ms QenBel × MyHarur brand reveal
class IntroAnimationScreen extends ConsumerStatefulWidget {
  const IntroAnimationScreen({super.key});

  @override
  ConsumerState<IntroAnimationScreen> createState() =>
      _IntroAnimationScreenState();
}

class _IntroAnimationScreenState extends ConsumerState<IntroAnimationScreen>
    with TickerProviderStateMixin {

  late final AnimationController _master;

  // Background
  late final Animation<double> _bgFadeIn;
  late final Animation<double> _bgShift;   // ambient glow movement

  // Signature reveal (canvas clip)
  late final Animation<double> _sigReveal;  // 0→1

  // Pen-tip glow (peaks during writing, fades at end)
  late final Animation<double> _penGlow;

  // Post-completion shimmer sweep
  late final Animation<double> _shimmer;

  // Hold opacity
  late final Animation<double> _signatureOpacity;

  // Crossfade
  late final Animation<double> _crossfade;

  // Act 3 brand
  late final Animation<double> _act3Fade;
  late final Animation<double> _qenbelScale;
  late final Animation<double> _qenbelFade;
  late final Animation<double> _dividerFade;
  late final Animation<double> _myharurFade;
  late final Animation<double> _myharurSlide;
  late final Animation<double> _taglineFade;

  // Exit
  late final Animation<double> _contentOpacity;

  // Boot result
  String? _pendingRoute;
  bool _animDone = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5600),
    );

    // Background
    _bgFadeIn = CurvedAnimation(parent: _master,
        curve: const Interval(0.0, 0.07, curve: Curves.easeOut));
    _bgShift = CurvedAnimation(parent: _master,
        curve: const Interval(0.0, 0.65, curve: Curves.easeInOut));

    // Signature draw: 400ms → 2600ms = 0.071 → 0.464
    _sigReveal = CurvedAnimation(parent: _master,
        curve: const Interval(0.071, 0.464, curve: _SignatureCurve()));

    // Pen glow: visible during drawing, fades as shimmer takes over
    _penGlow = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOut)), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0)
          .chain(CurveTween(curve: Curves.easeIn)), weight: 20),
    ]).animate(CurvedAnimation(parent: _master,
        curve: const Interval(0.071, 0.464)));

    // Shimmer: 2600ms → 3200ms = 0.464 → 0.571
    _shimmer = CurvedAnimation(parent: _master,
        curve: const Interval(0.464, 0.571, curve: Curves.easeInOut));

    // Signature stays solid during shimmer + hold
    _signatureOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOut)), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0)
          .chain(CurveTween(curve: Curves.easeIn)), weight: 15),
    ]).animate(CurvedAnimation(parent: _master,
        curve: const Interval(0.071, 0.643)));

    // Crossfade: 3600ms → 4300ms = 0.643 → 0.768
    _crossfade = CurvedAnimation(parent: _master,
        curve: const Interval(0.643, 0.768, curve: Curves.easeInOut));

    // Act 3
    _act3Fade = CurvedAnimation(parent: _master,
        curve: const Interval(0.75, 0.83, curve: Curves.easeOut));
    _qenbelFade = CurvedAnimation(parent: _master,
        curve: const Interval(0.75, 0.85, curve: Curves.easeOut));
    _qenbelScale = Tween<double>(begin: 0.90, end: 1.0).animate(
        CurvedAnimation(parent: _master,
            curve: const Interval(0.75, 0.87, curve: Curves.easeOutCubic)));
    _dividerFade = CurvedAnimation(parent: _master,
        curve: const Interval(0.84, 0.90, curve: Curves.easeOut));
    _myharurFade = CurvedAnimation(parent: _master,
        curve: const Interval(0.86, 0.93, curve: Curves.easeOut));
    _myharurSlide = Tween<double>(begin: 12.0, end: 0.0).animate(
        CurvedAnimation(parent: _master,
            curve: const Interval(0.86, 0.94, curve: Curves.easeOutCubic)));
    _taglineFade = CurvedAnimation(parent: _master,
        curve: const Interval(0.91, 0.97, curve: Curves.easeOut));

    _contentOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _master,
            curve: const Interval(0.97, 1.0, curve: Curves.easeIn)));

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
    final isDark   = ref.watch(themeProvider) == ThemeMode.dark;
    final size     = MediaQuery.of(context).size;
    final neutral  = isDark ? Colors.black : Colors.white;

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
                // ── Ambient animated amber background ─────────────────────
                Opacity(
                  opacity: _bgFadeIn.value * (1.0 - crossV),
                  child: _AmberBackground(shiftProgress: _bgShift.value),
                ),

                // ── Neutral background (crossfade target) ─────────────────
                Opacity(opacity: crossV, child: ColoredBox(color: neutral)),

                // ── Signature Act 1 ───────────────────────────────────────
                Opacity(
                  opacity: _signatureOpacity.value * (1.0 - crossV),
                  child: Center(
                    child: SizedBox(
                      width: size.width * 0.88,
                      height: 180,
                      child: CustomPaint(
                        painter: _SignaturePainter(
                          revealProgress: _sigReveal.value,
                          penGlowOpacity: _penGlow.value,
                          shimmerProgress: _shimmer.value,
                          containerWidth: size.width * 0.88,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Act 3: QenBel brand ───────────────────────────────────
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

// ─── Custom curve: slow for the H, faster flowing for emapriyan ───────────────
class _SignatureCurve extends Curve {
  const _SignatureCurve();
  @override
  double transformInternal(double t) {
    // H takes up ~30% of the time but only ~28% of the path
    if (t < 0.30) {
      return Curves.easeIn.transform(t / 0.30) * 0.28;
    }
    return 0.28 + Curves.easeInOut.transform((t - 0.30) / 0.70) * 0.72;
  }
}

// ─── Canvas-based signature painter ───────────────────────────────────────────
class _SignaturePainter extends CustomPainter {
  final double revealProgress;   // 0→1 clip reveal
  final double penGlowOpacity;   // pen tip intensity
  final double shimmerProgress;  // 0→1 shimmer sweep (0 = not started)
  final double containerWidth;

  const _SignaturePainter({
    required this.revealProgress,
    required this.penGlowOpacity,
    required this.shimmerProgress,
    required this.containerWidth,
  });

  static const _style = TextStyle(
    fontFamily: 'PinyonScript',
    fontSize: 90,
    color: Colors.white,
    letterSpacing: 1.5,
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (revealProgress <= 0.0) return;

    final tp = TextPainter(
      text: const TextSpan(text: 'Hemapriyan', style: _style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);

    final textX = (size.width - tp.width) / 2;
    final textY = (size.height - tp.height) / 2;
    final revealW = tp.width * revealProgress.clamp(0.0, 1.0);

    // ── 1. Draw revealed portion of signature ─────────────────────────────
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(textX - 4, 0, revealW + 8, size.height));
    tp.paint(canvas, Offset(textX, textY));
    canvas.restore();

    // ── 2. Pen-tip luminous cursor at leading edge ────────────────────────
    if (penGlowOpacity > 0.01 && revealProgress < 0.99) {
      final gx = textX + revealW;
      final gy = textY + tp.height * 0.58;

      // Amber outer bloom
      canvas.drawCircle(Offset(gx, gy), 26,
        Paint()
          ..color = const Color(0xFFD4700A).withOpacity(0.22 * penGlowOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22));
      // Warm white mid
      canvas.drawCircle(Offset(gx, gy), 11,
        Paint()
          ..color = Colors.white.withOpacity(0.55 * penGlowOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9));
      // Hard bright core
      canvas.drawCircle(Offset(gx, gy), 2.8,
        Paint()..color = Colors.white.withOpacity(0.95 * penGlowOpacity));
    }

    // ── 3. Shimmer sweep after completion ─────────────────────────────────
    if (shimmerProgress > 0.01) {
      final shimX = textX + tp.width * shimmerProgress;
      final shimW = tp.width * 0.18;
      final shimRect = Rect.fromCenter(
        center: Offset(shimX, textY + tp.height / 2),
        width: shimW, height: tp.height * 1.1,
      );

      canvas.save();
      canvas.clipRect(Rect.fromLTWH(textX, textY - 2, tp.width, tp.height + 4));
      canvas.drawRect(shimRect, Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withOpacity(0.22),
            Colors.white.withOpacity(0.38),
            Colors.white.withOpacity(0.22),
            Colors.transparent,
          ],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        ).createShader(shimRect));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter old) =>
      old.revealProgress != revealProgress ||
      old.penGlowOpacity != penGlowOpacity ||
      old.shimmerProgress != shimmerProgress;
}

// ─── Animated amber background ─────────────────────────────────────────────────
class _AmberBackground extends StatelessWidget {
  final double shiftProgress; // 0→1 — subtle glow drift left→right
  const _AmberBackground({required this.shiftProgress});

  @override
  Widget build(BuildContext context) {
    // Glow centre drifts slightly from left to right (cinematic sunrise feel)
    final cx = -0.25 + shiftProgress * 0.45;
    final cy = -0.20 + math.sin(shiftProgress * math.pi) * 0.08;

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(cx, cy),
          radius: 1.55,
          colors: const [
            Color(0xFFE8820A), // bright amber highlight
            Color(0xFFCC6400), // warm amber
            Color(0xFF8B3A00), // mid brown
            Color(0xFF3D1200), // deep brown
            Color(0xFF150500), // near black
          ],
          stops: const [0.0, 0.20, 0.42, 0.68, 1.0],
        ),
      ),
    );
  }
}

// ─── Act 3: QenBel × MyHarur ──────────────────────────────────────────────────
class _Act3Brand extends StatelessWidget {
  final bool isDark;
  final double screenWidth;
  final double qenbelFade, qenbelScale, dividerFade;
  final double myharurFade, myharurSlide, taglineFade;

  const _Act3Brand({
    required this.isDark, required this.screenWidth,
    required this.qenbelFade, required this.qenbelScale,
    required this.dividerFade, required this.myharurFade,
    required this.myharurSlide, required this.taglineFade,
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
                child: Text('MyHarur',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter', fontSize: 48,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -2.0, color: fg, height: 1.0,
                  )),
              ),
            ),
            const SizedBox(height: 10),
            // Tagline
            Opacity(
              opacity: taglineFade,
              child: Text('A QenBel Technologies Product',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter', fontSize: 12,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.4, color: subtle,
                )),
            ),
          ],
        ),
      ),
    );
  }
}
