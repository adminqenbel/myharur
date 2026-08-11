/// Configuration flag for Luxury UI Test APK builds.
/// When [isLuxuryUiTestBuild] is set to true:
/// 1. Intro video is bypassed on startup.
/// 2. Google Sign-In is replaced with Admin Login & Access Code Login.
/// 3. Dynamic Ambient Glow and Luxury Glass visual layer is enabled globally.
class TestConfig {
  static const bool isLuxuryUiTestBuild = false;
}
