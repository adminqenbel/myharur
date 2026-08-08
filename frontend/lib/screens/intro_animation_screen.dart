import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../api_client.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

class IntroAnimationScreen extends ConsumerStatefulWidget {
  const IntroAnimationScreen({super.key});

  @override
  ConsumerState<IntroAnimationScreen> createState() => _IntroAnimationScreenState();
}

class _IntroAnimationScreenState extends ConsumerState<IntroAnimationScreen>
    with TickerProviderStateMixin {

  // ── Controllers ───────────────────────────────────────────────────────────
  late AnimationController _masterCtrl;

  // Act 1 — Hemapriyan (amber)
  late Animation<double> _amberBgFade;       // 0.0 → 0.08 (bg fades in)
  late Animation<double> _personalLogoFade;  // 0.08 → 0.25 (logo fade)
  late Animation<double> _personalLogoScale; // 0.08 → 0.25 (subtle scale)
  late Animation<double> _personalLogoHold;  // 0.25 → 0.50 (hold)

  // Act 2 — Transition
  late Animation<double> _crossfade;         // 0.50 → 0.65 (amber → neutral)

  // Act 3 — QenBel's MyHarur
  late Animation<double> _qenbelFade;        // 0.65 → 0.78
  late Animation<double> _qenbelScale;       // 0.65 → 0.78
  late Animation<double> _myharurFade;       // 0.78 → 0.88
  late Animation<double> _taglineFade;       // 0.83 → 0.93
  late Animation<double> _exitFade;          // 0.93 → 1.00 (fade out)

  // Background color tween
  late Animation<Color?> _bgColor;

  @override
  void initState() {
    super.initState();

    // Set immersive full-screen (hide status bar during intro)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Total duration: 4.8 seconds
    _masterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    );

    // ── Act 1 — Hemapriyan ──────────────────────────────────────────────────
    _amberBgFade = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.0, 0.08, curve: Curves.easeOut),
    );

    _personalLogoFade = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.08, 0.28, curve: Curves.easeOut),
    );

    _personalLogoScale = Tween<double>(begin: 1.06, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.08, 0.32, curve: Curves.easeOutCubic),
      ),
    );

    // ── Act 2 — Crossfade ───────────────────────────────────────────────────
    _crossfade = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.50, 0.68, curve: Curves.easeInOut),
    );

    // ── Act 3 — QenBel's MyHarur ────────────────────────────────────────────
    _qenbelFade = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.66, 0.80, curve: Curves.easeOut),
    );

    _qenbelScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.66, 0.82, curve: Curves.easeOutCubic),
      ),
    );

    _myharurFade = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.78, 0.90, curve: Curves.easeOut),
    );

    _taglineFade = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.84, 0.94, curve: Curves.easeOut),
    );

    // ── Exit ────────────────────────────────────────────────────────────────
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.93, 1.0, curve: Curves.easeIn),
      ),
    );

    // Start animation then boot
    _masterCtrl.forward().then((_) => _boot());
  }

  @override
  void dispose() {
    _masterCtrl.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _boot() async {
    try {
      await ApiClient.dio.get('/config/');
    } catch (_) {}

    await ref.read(authProvider.notifier).tryAutoLogin();
    final auth = ref.read(authProvider);

    if (!mounted) return;

    // Restore system UI before navigating
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
    final screenSize = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _masterCtrl,
      builder: (context, _) {
        // Current phase detection
        final phase = _masterCtrl.value;
        final isInAct1 = phase < 0.50;
        final transitionProgress = _crossfade.value; // 0 = amber, 1 = neutral

        // ── Dynamic background ──────────────────────────────────────────────
        // Act 1: Warm amber gradient
        // Act 2/3: Clean white (light) or pure black (dark)
        final neutralBg = isDark ? Colors.black : Colors.white;
        final act1Bg1 = const Color(0xFF1A0800);   // deep warm brown
        final act1Bg2 = const Color(0xFF8B3A00);   // amber mid
        final act1Bg3 = const Color(0xFFD4700A);   // golden amber

        // Fade between amber bg and neutral
        final bgOpacity = _amberBgFade.value;

        return Scaffold(
          backgroundColor: Colors.black,
          body: Opacity(
            opacity: _exitFade.value,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Act 1 Background: Amber gradient ─────────────────────
                Opacity(
                  opacity: bgOpacity * (1.0 - transitionProgress),
                  child: _AmberGradientBackground(
                    size: screenSize,
                  ),
                ),

                // ── Act 2/3 Background: Clean neutral ────────────────────
                Opacity(
                  opacity: transitionProgress,
                  child: Container(color: neutralBg),
                ),

                // ── Act 1: Hemapriyan Logo ────────────────────────────────
                Opacity(
                  opacity: _personalLogoFade.value * (1.0 - transitionProgress),
                  child: Transform.scale(
                    scale: _personalLogoScale.value,
                    child: Center(
                      child: Container(
                        width: screenSize.width * 0.72,
                        height: screenSize.width * 0.72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Image.asset(
                          'assets/personal_logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Act 3: QenBel + MyHarur ───────────────────────────────
                Opacity(
                  opacity: transitionProgress,
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
                              width: screenSize.width * 0.52,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // MyHarur wordmark
                        Opacity(
                          opacity: _myharurFade.value,
                          child: Text(
                            'MyHarur',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 42,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1.5,
                              color: isDark ? Colors.white : Colors.black,
                              height: 1.0,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Tagline
                        Opacity(
                          opacity: _taglineFade.value,
                          child: Text(
                            'A QenBel Technologies Product',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.2,
                              color: isDark
                                  ? Colors.white.withOpacity(0.45)
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
          ),
        );
      },
    );
  }
}

/// Animated warm amber gradient — painted background for Act 1
class _AmberGradientBackground extends StatelessWidget {
  final Size size;
  const _AmberGradientBackground({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.2, -0.1),
          radius: 1.4,
          colors: [
            Color(0xFFD4700A), // golden amber highlight
            Color(0xFF8B3A00), // warm amber mid
            Color(0xFF3D1200), // deep warm brown
            Color(0xFF1A0800), // almost black-brown
          ],
          stops: [0.0, 0.35, 0.65, 1.0],
        ),
      ),
    );
  }
}
