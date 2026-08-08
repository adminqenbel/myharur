import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../api_client.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

// ─── Intro Animation Screen ────────────────────────────────────────────────────
// Act 1 (0–2.6s): HEMAPRIYAN written stroke-by-stroke on warm amber gradient
// Act 2 (2.6–3.3s): Crossfade amber → neutral white/dark
// Act 3 (3.3–5.0s): QenBel logo + MyHarur + tagline
//
// BLACK-SCREEN FIX: _boot() runs immediately in parallel with the animation.
// Navigation fires the instant the animation ends (no extra wait).
// ──────────────────────────────────────────────────────────────────────────────
class IntroAnimationScreen extends ConsumerStatefulWidget {
  const IntroAnimationScreen({super.key});

  @override
  ConsumerState<IntroAnimationScreen> createState() =>
      _IntroAnimationScreenState();
}

class _IntroAnimationScreenState extends ConsumerState<IntroAnimationScreen>
    with TickerProviderStateMixin {

  late final AnimationController _master;

  // ── Act 1 — Amber bg ────────────────────────────────────────────────────────
  late final Animation<double> _amberIn;

  // ── Act 1 — Staggered letter write-on ───────────────────────────────────────
  late final List<Animation<double>> _letterProgress;
  late final Animation<double> _writeProgress;

  // ── Act 2 — Crossfade ───────────────────────────────────────────────────────
  late final Animation<double> _crossfade;

  // ── Act 3 — QenBel brand ────────────────────────────────────────────────────
  late final Animation<double> _act3Fade;       // entire act 3 container
  late final Animation<double> _qenbelScale;
  late final Animation<double> _qenbelFade;
  late final Animation<double> _dividerFade;
  late final Animation<double> _myharurFade;
  late final Animation<double> _myharurSlide;
  late final Animation<double> _taglineFade;

  // ── Exit ─────────────────────────────────────────────────────────────────────
  // Fades to neutral (not black) — eliminates the black-screen flash
  late final Animation<double> _contentOpacity; // 1→0 at end
  late final Animation<Color?> _bgColor;        // black→neutral during crossfade

  // ── Boot result stored here so navigation fires instantly ───────────────────
  String? _pendingRoute;
  bool _animationDone = false;

  static const String _letters = 'HEMAPRIYAN';
  static const int    _letterCount = 10;

  static const double _writeStart = 0.07;
  static const double _writeEnd   = 0.52;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );

    // ── Amber bg ──────────────────────────────────────────────────────────────
    _amberIn = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.0, 0.06, curve: Curves.easeOut),
    );

    // ── Staggered letters ─────────────────────────────────────────────────────
    const letterSpan = _writeEnd - _writeStart;
    const slotSize   = letterSpan / (_letterCount * 0.70);
    _letterProgress = List.generate(_letterCount, (i) {
      final start = _writeStart + i * (letterSpan / _letterCount) * 0.72;
      final end   = (start + slotSize * 0.85).clamp(0.0, _writeEnd + 0.04);
      return CurvedAnimation(
        parent: _master,
        curve: Interval(start, end, curve: Curves.easeOut),
      );
    });

    _writeProgress = CurvedAnimation(
      parent: _master,
      curve: const Interval(_writeStart, _writeEnd, curve: Curves.easeInOut),
    );

    // ── Crossfade ─────────────────────────────────────────────────────────────
    _crossfade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.55, 0.70, curve: Curves.easeInOut),
    );

    // ── Act 3 ─────────────────────────────────────────────────────────────────
    _act3Fade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.68, 0.76, curve: Curves.easeOut),
    );
    _qenbelFade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.68, 0.80, curve: Curves.easeOut),
    );
    _qenbelScale = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.68, 0.82, curve: Curves.easeOutCubic),
      ),
    );
    _dividerFade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.78, 0.86, curve: Curves.easeOut),
    );
    _myharurFade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.80, 0.90, curve: Curves.easeOut),
    );
    _myharurSlide = Tween<double>(begin: 12.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.80, 0.92, curve: Curves.easeOutCubic),
      ),
    );
    _taglineFade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.88, 0.96, curve: Curves.easeOut),
    );

    // ── Exit: fade content to 0, NOT the background ──────────────────────────
    // This means the scaffold color (neutral) stays visible, no black flash
    _contentOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.95, 1.0, curve: Curves.easeIn),
      ),
    );

    // ── Start animation ───────────────────────────────────────────────────────
    _master.forward().then((_) => _onAnimationComplete());

    // ── Boot runs NOW in parallel — result stored for instant navigation ───────
    _runBoot();
  }

  Future<void> _runBoot() async {
    try { await ApiClient.dio.get('/config/'); } catch (_) {}
    await ref.read(authProvider.notifier).tryAutoLogin();
    final auth = ref.read(authProvider);

    String route;
    if (!auth.isLoggedIn)            route = '/login';
    else if (auth.usernameRequired)   route = '/username-setup';
    else if (!auth.isSetupComplete)   route = '/onboarding';
    else                              route = '/home';

    _pendingRoute = route;

    // If animation already finished while boot was running, navigate now
    if (_animationDone && mounted) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      context.go(route);
    }
  }

  void _onAnimationComplete() {
    _animationDone = true;
    if (_pendingRoute != null && mounted) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      context.go(_pendingRoute!);
    }
    // If boot not done yet, _runBoot() will navigate when it completes
    // Meanwhile the app stays on the last frame of Act 3 (no black screen)
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
    // Neutral color matches the app's actual background so exit is seamless
    final neutralBg = isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);

    return AnimatedBuilder(
      animation: _master,
      builder: (context, _) {
        final crossV = _crossfade.value;

        return Scaffold(
          // ── Scaffold bg = neutral. So when content fades out there's no black ──
          backgroundColor: neutralBg,
          body: Opacity(
            opacity: _contentOpacity.value,
            child: Stack(
              fit: StackFit.expand,
              children: [

                // ── Amber gradient (Act 1) ──────────────────────────────────
                Opacity(
                  opacity: _amberIn.value * (1.0 - crossV),
                  child: const _AmberBg(),
                ),

                // ── Neutral overlay (Act 2/3 background) ───────────────────
                Opacity(
                  opacity: crossV,
                  child: ColoredBox(color: neutralBg),
                ),

                // ── Act 1: Writing animation ────────────────────────────────
                Opacity(
                  opacity: (1.0 - crossV).clamp(0.0, 1.0),
                  child: Center(
                    child: _HemapriyanWriter(
                      letterProgress: _letterProgress,
                      writeProgress: _writeProgress.value,
                      screenWidth: size.width,
                    ),
                  ),
                ),

                // ── Act 3: QenBel × MyHarur ────────────────────────────────
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
          ),
        );
      },
    );
  }
}

// ─── Act 3 Brand Widget ────────────────────────────────────────────────────────
// Professionally centered QenBel logo → divider → MyHarur wordmark → tagline
class _Act3Brand extends StatelessWidget {
  final bool   isDark;
  final double screenWidth;
  final double qenbelFade;
  final double qenbelScale;
  final double dividerFade;
  final double myharurFade;
  final double myharurSlide;
  final double taglineFade;

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
    final textColor     = isDark ? Colors.white : Colors.black;
    final subtleColor   = isDark
        ? Colors.white.withOpacity(0.35)
        : Colors.black.withOpacity(0.30);
    final dividerColor  = isDark
        ? Colors.white.withOpacity(0.15)
        : Colors.black.withOpacity(0.10);

    return Center(
      child: SizedBox(
        width: screenWidth * 0.80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            // ── QenBel logo ──────────────────────────────────────────────────
            Opacity(
              opacity: qenbelFade,
              child: Transform.scale(
                scale: qenbelScale,
                child: Image.asset(
                  isDark ? 'assets/qenbel_dark.png' : 'assets/qenbel_light.png',
                  width: screenWidth * 0.50,
                  height: 52,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Thin divider ─────────────────────────────────────────────────
            Opacity(
              opacity: dividerFade,
              child: Container(
                width: 32,
                height: 1,
                color: dividerColor,
              ),
            ),

            const SizedBox(height: 24),

            // ── MyHarur wordmark ─────────────────────────────────────────────
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
                    color: textColor,
                    height: 1.0,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ── Tagline ──────────────────────────────────────────────────────
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
                  color: subtleColor,
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

// ─── Hemapriyan Writing Widget ─────────────────────────────────────────────────
class _HemapriyanWriter extends StatelessWidget {
  final List<Animation<double>> letterProgress;
  final double writeProgress;
  final double screenWidth;

  const _HemapriyanWriter({
    required this.letterProgress,
    required this.writeProgress,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HemapriyanPainter(
        letterProgress: letterProgress.map((a) => a.value).toList(),
        writeProgress: writeProgress,
        screenWidth: screenWidth,
      ),
      size: Size(screenWidth * 0.88, 160),
    );
  }
}

// ─── Custom Painter ────────────────────────────────────────────────────────────
class _HemapriyanPainter extends CustomPainter {
  final List<double> letterProgress;
  final double writeProgress;
  final double screenWidth;

  static const String _text = 'HEMAPRIYAN';

  const _HemapriyanPainter({
    required this.letterProgress,
    required this.writeProgress,
    required this.screenWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const style = TextStyle(
      fontFamily: 'GreatVibes',
      fontSize: 96,
      letterSpacing: 2,
      color: Colors.white,
    );

    // Measure full text for centering
    final fullP = TextPainter(
      text: const TextSpan(text: _text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    final startX = (size.width - fullP.width) / 2;
    final topY   = size.height / 2 - fullP.height / 2;

    double cursorX = startX;
    double cursorY = topY + fullP.height * 0.6;

    for (int i = 0; i < _text.length; i++) {
      final progress = letterProgress[i].clamp(0.0, 1.0);
      if (progress <= 0.0) continue;

      final letter = _text[i];

      // Prefix width for x-position
      final prefixP = TextPainter(
        text: TextSpan(
          text: _text.substring(0, i),
          style: style,
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final letterX = startX + prefixP.width;

      // Letter with fade + settle
      final letterStyle = style.copyWith(
        color: Colors.white.withOpacity(progress),
        shadows: progress > 0.4
            ? [
                Shadow(
                  color: Colors.white.withOpacity(0.22 * progress),
                  blurRadius: 16,
                ),
                Shadow(
                  color: const Color(0xFFD4700A).withOpacity(0.28 * progress),
                  blurRadius: 28,
                ),
              ]
            : null,
      );

      final letterP = TextPainter(
        text: TextSpan(text: letter, style: letterStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      final ySettle = (1.0 - progress) * -5.0; // drops from above

      letterP.paint(canvas, Offset(letterX, topY + ySettle));

      if (progress > 0.25) {
        cursorX = letterX + letterP.width;
        cursorY = topY + fullP.height * 0.62;
      }
    }

    // ── Glowing pen-tip cursor ─────────────────────────────────────────────
    if (writeProgress > 0.02 && writeProgress < 0.97) {
      final glow = math.sin(writeProgress * math.pi).clamp(0.0, 1.0);

      canvas.drawCircle(
        Offset(cursorX, cursorY),
        22,
        Paint()
          ..color = const Color(0xFFD4700A).withOpacity(0.25 * glow)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
      canvas.drawCircle(
        Offset(cursorX, cursorY),
        9,
        Paint()
          ..color = Colors.white.withOpacity(0.55 * glow)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
      canvas.drawCircle(
        Offset(cursorX, cursorY),
        3,
        Paint()..color = Colors.white.withOpacity(0.95 * glow),
      );
    }
  }

  @override
  bool shouldRepaint(_HemapriyanPainter old) =>
      old.writeProgress != writeProgress ||
      old.letterProgress.toString() != letterProgress.toString();
}

// ─── Amber Background ──────────────────────────────────────────────────────────
class _AmberBg extends StatelessWidget {
  const _AmberBg();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.2, -0.15),
          radius: 1.5,
          colors: [
            Color(0xFFD4700A),
            Color(0xFF8B3A00),
            Color(0xFF3D1200),
            Color(0xFF1A0800),
          ],
          stops: [0.0, 0.32, 0.62, 1.0],
        ),
      ),
    );
  }
}
