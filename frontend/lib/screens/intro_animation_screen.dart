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
// Act 2 (2.6–3.3s): Crossfade amber → neutral white/black
// Act 3 (3.3–4.9s): QenBel logo + MyHarur + tagline fade in
// ──────────────────────────────────────────────────────────────────────────────
class IntroAnimationScreen extends ConsumerStatefulWidget {
  const IntroAnimationScreen({super.key});

  @override
  ConsumerState<IntroAnimationScreen> createState() =>
      _IntroAnimationScreenState();
}

class _IntroAnimationScreenState extends ConsumerState<IntroAnimationScreen>
    with TickerProviderStateMixin {

  // Master controller driving everything
  late final AnimationController _master;

  // ── Act 1 — Amber bg ────────────────────────────────────────────────────────
  late final Animation<double> _amberIn;   // bg fades in

  // ── Act 1 — Text write-on ───────────────────────────────────────────────────
  // Each letter of HEMAPRIYAN gets its own progress value, staggered
  late final List<Animation<double>> _letterProgress;

  // ── Act 1 — Glow cursor that follows the writing ────────────────────────────
  // Combined progress value 0→1 covering the full write span
  late final Animation<double> _writeProgress;

  // ── Act 2 — Crossfade ───────────────────────────────────────────────────────
  late final Animation<double> _crossfade;

  // ── Act 3 — QenBel brand ────────────────────────────────────────────────────
  late final Animation<double> _qenbelFade;
  late final Animation<double> _qenbelScale;
  late final Animation<double> _myharurFade;
  late final Animation<double> _myharurSlide;
  late final Animation<double> _taglineFade;

  // ── Exit ─────────────────────────────────────────────────────────────────────
  late final Animation<double> _exitOpacity;

  static const String _letters = 'HEMAPRIYAN';
  static const int _letterCount = 10;

  // Timeline fractions (of 4900ms total)
  // 0.0 → 0.06: amber bg fade
  // 0.06 → 0.52: letters write in (staggered)
  // 0.52 → 0.56: hold
  // 0.56 → 0.68: crossfade
  // 0.68 → 0.82: QenBel in
  // 0.82 → 0.90: MyHarur in
  // 0.90 → 0.96: tagline in
  // 0.96 → 1.00: fade out
  static const double _writeStart = 0.07;
  static const double _writeEnd   = 0.52;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4900),
    );

    // ── Amber bg ──────────────────────────────────────────────────────────────
    _amberIn = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.0, 0.06, curve: Curves.easeOut),
    );

    // ── Staggered letter animations ───────────────────────────────────────────
    const letterSpan = _writeEnd - _writeStart; // 0.45
    // Each letter occupies 60% of its slot; slots overlap by 40%
    const slotSize   = letterSpan / (_letterCount * 0.70);
    _letterProgress = List.generate(_letterCount, (i) {
      final start = _writeStart + i * (letterSpan / _letterCount) * 0.72;
      final end   = (start + slotSize * 0.85).clamp(0.0, _writeEnd + 0.04);
      return CurvedAnimation(
        parent: _master,
        curve: Interval(start, end, curve: Curves.easeOut),
      );
    });

    // Glow cursor: full write-on span
    _writeProgress = CurvedAnimation(
      parent: _master,
      curve: const Interval(_writeStart, _writeEnd, curve: Curves.easeInOut),
    );

    // ── Crossfade ─────────────────────────────────────────────────────────────
    _crossfade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.55, 0.70, curve: Curves.easeInOut),
    );

    // ── QenBel brand ──────────────────────────────────────────────────────────
    _qenbelFade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.68, 0.82, curve: Curves.easeOut),
    );
    _qenbelScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.68, 0.84, curve: Curves.easeOutCubic),
      ),
    );
    _myharurFade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.82, 0.91, curve: Curves.easeOut),
    );
    _myharurSlide = Tween<double>(begin: 10.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.82, 0.92, curve: Curves.easeOutCubic),
      ),
    );
    _taglineFade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.89, 0.96, curve: Curves.easeOut),
    );

    // ── Exit ──────────────────────────────────────────────────────────────────
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.95, 1.0, curve: Curves.easeIn),
      ),
    );

    _master.forward().then((_) => _boot());
  }

  @override
  void dispose() {
    _master.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _boot() async {
    try { await ApiClient.dio.get('/config/'); } catch (_) {}
    await ref.read(authProvider.notifier).tryAutoLogin();
    final auth = ref.read(authProvider);
    if (!mounted) return;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (!auth.isLoggedIn) {
      context.go('/login');
    } else if (auth.usernameRequired) {
      context.go('/username-setup');
    } else if (!auth.isSetupComplete) {
      context.go('/onboarding');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final size   = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _master,
        builder: (context, _) {
          final crossV = _crossfade.value;
          final neutral = isDark ? Colors.black : Colors.white;

          return Opacity(
            opacity: _exitOpacity.value,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Amber gradient background (Act 1) ────────────────────────
                Opacity(
                  opacity: _amberIn.value * (1.0 - crossV),
                  child: const _AmberBg(),
                ),

                // ── Neutral background (Act 2/3) ─────────────────────────────
                Opacity(
                  opacity: crossV,
                  child: ColoredBox(color: neutral),
                ),

                // ── Act 1: Writing animation ──────────────────────────────────
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

                // ── Act 3: QenBel brand ───────────────────────────────────────
                Opacity(
                  opacity: crossV,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // QenBel logo
                        Opacity(
                          opacity: _qenbelFade.value,
                          child: Transform.scale(
                            scale: _qenbelScale.value,
                            child: Image.asset(
                              isDark
                                  ? 'assets/qenbel_dark.png'
                                  : 'assets/qenbel_light.png',
                              width: size.width * 0.52,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        // MyHarur wordmark
                        Opacity(
                          opacity: _myharurFade.value,
                          child: Transform.translate(
                            offset: Offset(0, _myharurSlide.value),
                            child: Text(
                              'MyHarur',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 40,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -1.4,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Tagline
                        Opacity(
                          opacity: _taglineFade.value,
                          child: Text(
                            'A QenBel Technologies Product',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.3,
                              color: isDark
                                  ? Colors.white.withOpacity(0.42)
                                  : Colors.black.withOpacity(0.38),
                            ),
                          ),
                        ),
                      ],
                    ),
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

// ─── Hemapriyan Writing Widget ─────────────────────────────────────────────────
// Draws each letter of HEMAPRIYAN progressively, with a glowing cursor
// following the leading stroke edge.
class _HemapriyanWriter extends StatelessWidget {
  final List<Animation<double>> letterProgress;
  final double writeProgress; // 0→1 overall write progress for cursor
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

// ─── Custom Painter — renders HEMAPRIYAN with animated letter reveal ────────────
class _HemapriyanPainter extends CustomPainter {
  final List<double> letterProgress;
  final double writeProgress;
  final double screenWidth;

  static const String _text = 'HEMAPRIYAN';

  _HemapriyanPainter({
    required this.letterProgress,
    required this.writeProgress,
    required this.screenWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── Font setup ─────────────────────────────────────────────────────────────
    // Measure total text width first for centering
    final fullPainter = TextPainter(
      text: TextSpan(
        text: _text,
        style: const TextStyle(
          fontFamily: 'GreatVibes',
          fontSize: 96,
          color: Colors.white,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final totalWidth = fullPainter.width;
    final startX = (size.width - totalWidth) / 2;
    final baseY = size.height / 2 + 28;

    // ── Draw each letter with its own opacity based on progress ────────────────
    double cursorX = startX;
    double cursorY = baseY;

    for (int i = 0; i < _text.length; i++) {
      final letter = _text[i];
      final progress = letterProgress[i].clamp(0.0, 1.0);

      if (progress <= 0.0) {
        // Measure and skip cursor position ahead
        final measurer = TextPainter(
          text: TextSpan(
            text: letter,
            style: const TextStyle(
              fontFamily: 'GreatVibes',
              fontSize: 96,
              color: Colors.transparent,
              letterSpacing: 2,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        // Don't advance cursor for unrendered letters
        continue;
      }

      // Letter paint: fade in + slight vertical drift settling
      final letterStyle = TextStyle(
        fontFamily: 'GreatVibes',
        fontSize: 96,
        letterSpacing: 2,
        color: Colors.white.withOpacity(progress),
        shadows: progress > 0.5
            ? [
                Shadow(
                  color: Colors.white.withOpacity(0.25 * progress),
                  blurRadius: 18,
                ),
                Shadow(
                  color: const Color(0xFFD4700A).withOpacity(0.3 * progress),
                  blurRadius: 30,
                ),
              ]
            : null,
      );

      // Measure prefix to find this letter's x position
      final prefixPainter = TextPainter(
        text: TextSpan(
          text: _text.substring(0, i),
          style: const TextStyle(
            fontFamily: 'GreatVibes',
            fontSize: 96,
            letterSpacing: 2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final letterX = startX + prefixPainter.width;

      // Measure this letter width
      final letterPainter = TextPainter(
        text: TextSpan(text: letter, style: letterStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      // Subtle vertical settle: drops slightly from above
      final yOffset = (1.0 - progress) * -6.0;

      letterPainter.paint(
        canvas,
        Offset(letterX, baseY - fullPainter.height + yOffset),
      );

      // Update cursor to right edge of this letter (for glow placement)
      if (progress > 0.3) {
        cursorX = letterX + letterPainter.width;
        cursorY = baseY - fullPainter.height / 2;
      }
    }

    // ── Glowing pen-tip cursor ─────────────────────────────────────────────────
    if (writeProgress > 0.02 && writeProgress < 0.98) {
      final glowOpacity = math.sin(writeProgress * math.pi).clamp(0.0, 1.0);

      // Outer amber glow
      canvas.drawCircle(
        Offset(cursorX, cursorY + 8),
        22,
        Paint()
          ..color = const Color(0xFFD4700A).withOpacity(0.28 * glowOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );

      // Mid white glow
      canvas.drawCircle(
        Offset(cursorX, cursorY + 8),
        10,
        Paint()
          ..color = Colors.white.withOpacity(0.6 * glowOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      // Core bright dot
      canvas.drawCircle(
        Offset(cursorX, cursorY + 8),
        3.5,
        Paint()..color = Colors.white.withOpacity(0.95 * glowOpacity),
      );
    }

    // ── Trailing ambient shimmer under text ────────────────────────────────────
    if (writeProgress > 0.1 && writeProgress < 0.95) {
      final shimmerPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(0.06),
            Colors.transparent,
          ],
          radius: 0.5,
        ).createShader(Rect.fromCenter(
          center: Offset(size.width / 2, baseY - 20),
          width: totalWidth * 1.1,
          height: 60,
        ));
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(size.width / 2, baseY - 20),
          width: totalWidth * 1.1,
          height: 60,
        ),
        shimmerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_HemapriyanPainter old) =>
      old.writeProgress != writeProgress ||
      old.letterProgress != letterProgress;
}

// ─── Warm Amber Background ─────────────────────────────────────────────────────
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
            Color(0xFFD4700A), // golden amber highlight
            Color(0xFF8B3A00), // warm amber mid
            Color(0xFF3D1200), // deep warm brown
            Color(0xFF1A0800), // near-black brown
          ],
          stops: [0.0, 0.32, 0.62, 1.0],
        ),
      ),
    );
  }
}
