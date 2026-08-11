import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../api_client.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

/// Cinematic Intro: Plays the enhanced 1080p Full HD extended signature reveal video
/// ("assets/personal_intro.mp4", 10.8s duration), followed by a smooth crossfade into Act 3 (QenBel × MyHarur).
///
/// Timeline (11800ms total):
///  0–7800ms   Act 1: Full HD extended signature reveal video (drawing phase)
///  7800–10200ms Signature holds clean and sharp
///  10200–10800ms Act 2: Smooth crossfade from video to neutral background
///  10800–11800ms Act 3: QenBel × MyHarur brand reveal
class IntroAnimationScreen extends ConsumerStatefulWidget {
  const IntroAnimationScreen({super.key});

  @override
  ConsumerState<IntroAnimationScreen> createState() =>
      _IntroAnimationScreenState();
}

class _IntroAnimationScreenState extends ConsumerState<IntroAnimationScreen>
    with TickerProviderStateMixin {

  late final AnimationController _master;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  // Crossfade from video/amber → neutral theme
  late final Animation<double> _crossfade;

  // Act 3 brand reveal animations
  late final Animation<double> _act3Fade;
  late final Animation<double> _qenbelScale;
  late final Animation<double> _qenbelFade;
  late final Animation<double> _dividerFade;
  late final Animation<double> _myharurFade;
  late final Animation<double> _myharurSlide;
  late final Animation<double> _taglineFade;

  // Exit opacity transition
  late final Animation<double> _contentOpacity;

  // Boot status tracker
  String? _pendingRoute;
  bool _animDone = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 11800),
    );

    // Crossfade amber/video → neutral: 10200ms → 10800ms (0.864 → 0.915)
    _crossfade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.864, 0.915, curve: Curves.easeInOut),
    );

    // Act 3 QenBel branding: 10600ms → 11800ms
    _act3Fade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.898, 0.940, curve: Curves.easeOut),
    );
    _qenbelFade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.898, 0.949, curve: Curves.easeOut),
    );
    _qenbelScale = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.898, 0.958, curve: Curves.easeOutCubic),
      ),
    );
    _dividerFade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.924, 0.966, curve: Curves.easeOut),
    );
    _myharurFade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.940, 0.975, curve: Curves.easeOut),
    );
    _myharurSlide = Tween<double>(begin: 12.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.940, 0.975, curve: Curves.easeOutCubic),
      ),
    );
    _taglineFade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.958, 0.990, curve: Curves.easeOut),
    );

    _contentOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.985, 1.0, curve: Curves.easeIn),
      ),
    );

    _initVideo();
    _master.forward().then((_) => _onAnimDone());
    _runBoot();
  }

  Future<void> _initVideo() async {
    try {
      _videoController = VideoPlayerController.asset('assets/personal_intro.mp4');
      await _videoController!.initialize();
      _videoController!.setVolume(0.0);
      _videoController!.play();
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Video initialization fallback: $e');
    }
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
    _videoController?.dispose();
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
                // ── Warm Amber Background Base ───────────────────────────────
                Opacity(
                  opacity: 1.0 - crossV,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0.0, -0.10),
                        radius: 1.40,
                        colors: [
                          Color(0xFFE8820A),
                          Color(0xFF8B3A00),
                          Color(0xFF3D1200),
                          Color(0xFF140400),
                        ],
                        stops: [0.0, 0.35, 0.70, 1.0],
                      ),
                    ),
                  ),
                ),

                // ── Neutral Background (Crossfade Target) ────────────────────
                Opacity(opacity: crossV, child: ColoredBox(color: neutral)),

                // ── Act 1 Video Reveal ───────────────────────────────────────
                Opacity(
                  opacity: 1.0 - crossV,
                  child: Center(
                    child: _isVideoInitialized && _videoController != null
                        ? SizedBox.expand(
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _videoController!.value.size.width,
                                height: _videoController!.value.size.height,
                                child: VideoPlayer(_videoController!),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),

                // ── Act 3 Brand Reveal (QenBel × MyHarur) ─────────────────────
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

// ─── Act 3 Brand Reveal Widget ────────────────────────────────────────────────
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
            // QenBel Logo
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
            // Thin Divider Line
            Opacity(
              opacity: dividerFade,
              child: Container(width: 28, height: 1, color: div),
            ),
            const SizedBox(height: 22),
            // MyHarur Wordmark
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
            // Product Tagline
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
