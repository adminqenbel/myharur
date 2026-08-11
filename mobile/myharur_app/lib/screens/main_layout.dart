import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/translations.dart';
import '../utils/update_manager.dart';
import '../theme.dart';
import '../theme/luxury_theme.dart';
import '../config/test_config.dart';
import '../widgets/luxury/ambient_background.dart';
import '../widgets/luxury/glass_surface.dart';
import 'dart:async';
import '../services/socket_service.dart';
import '../services/notification_service.dart';

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  StreamSubscription? _mentionSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateManager.checkUpdate(context);
    });
    
    // Listen for socket mentions to trigger push notifications
    _mentionSub = SocketService().onMention.listen((data) {
      final senderName = data['sender_name'] ?? 'Someone';
      final content = data['content'] ?? '';
      NotificationService().showNotification(
        title: 'You were mentioned!',
        body: '$senderName mentioned you: $content',
      );
    });
  }

  @override
  void dispose() {
    _mentionSub?.cancel();
    super.dispose();
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/market')) return 1;
    if (location.startsWith('/community')) return 2;
    if (location.startsWith('/report')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0: context.go('/home'); break;
      case 1: context.go('/market'); break;
      case 2: context.go('/community'); break;
      case 3: context.go('/report'); break;
      case 4: context.go('/profile'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final int selectedIndex = _calculateSelectedIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark || TestConfig.isLuxuryUiTestBuild;

    final Widget bodyContent = TestConfig.isLuxuryUiTestBuild
        ? AmbientBackground(child: widget.child)
        : widget.child;

    return Scaffold(
      extendBody: true,
      backgroundColor: TestConfig.isLuxuryUiTestBuild ? LuxuryColors.deepBackground : null,
      body: bodyContent,
      bottomNavigationBar: isKeyboardOpen
          ? null
          : SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: TestConfig.isLuxuryUiTestBuild 
                          ? LuxuryColors.racingRed.withOpacity(0.2) 
                          : Colors.black.withOpacity(0.15), 
                      blurRadius: 30, 
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: TestConfig.isLuxuryUiTestBuild 
                            ? const Color(0x2E1A0000)
                            : Theme.of(context).colorScheme.surface.withOpacity(isDark ? 0.35 : 0.5),
                        border: Border.all(
                          color: TestConfig.isLuxuryUiTestBuild 
                              ? Colors.white.withOpacity(0.15)
                              : (isDark ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.4)),
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNavItem(0, Icons.explore_rounded, l(ref, 'Explore'), selectedIndex, isDark),
                          _buildNavItem(1, Icons.storefront_rounded, l(ref, 'Market'), selectedIndex, isDark),
                          _buildNavItem(2, Icons.forum_rounded, l(ref, 'Community'), selectedIndex, isDark),
                          _buildNavItem(3, Icons.campaign_rounded, l(ref, 'Report'), selectedIndex, isDark),
                          _buildNavItem(4, Icons.person_rounded, l(ref, 'Profile'), selectedIndex, isDark),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, int selectedIndex, bool isDark) {
    final bool isSelected = index == selectedIndex;
    final Color activeColor = TestConfig.isLuxuryUiTestBuild ? LuxuryColors.champagneGold : AppTheme.appleBlue;
    final Color inactiveColor = isDark ? Colors.white.withOpacity(0.5) : AppTheme.textSecondaryLight;
    
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 18 : 12, 
          vertical: 10
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? (TestConfig.isLuxuryUiTestBuild 
                  ? LuxuryColors.redGlass 
                  : activeColor.withOpacity(0.15)) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected && TestConfig.isLuxuryUiTestBuild
              ? Border.all(color: LuxuryColors.champagneGold.withOpacity(0.4), width: 1.2)
              : null,
          boxShadow: isSelected && TestConfig.isLuxuryUiTestBuild ? [
            BoxShadow(
              color: LuxuryColors.racingRed.withOpacity(0.30),
              blurRadius: 16,
              spreadRadius: 1,
            )
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 250),
              child: Icon(
                icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 24,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected && TestConfig.isLuxuryUiTestBuild ? LuxuryColors.primaryText : activeColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.2,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
