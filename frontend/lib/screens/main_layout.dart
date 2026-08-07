import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/translations.dart';
import '../utils/update_manager.dart';
import '../theme.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: isKeyboardOpen
          ? null
          : SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(isDark ? 0.4 : 0.1), blurRadius: 35, offset: const Offset(0, 10))
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withOpacity(isDark ? 0.25 : 0.65),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.4),
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
    final Color activeColor = AppTheme.appleBlue;
    final Color inactiveColor = isDark ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5) : AppTheme.textSecondaryLight;
    
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              transform: Matrix4.identity()..scale(isSelected ? 1.15 : 1.0),
              child: Icon(
                icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 26,
                shadows: isSelected ? [BoxShadow(color: activeColor.withOpacity(0.4), blurRadius: 10, offset: Offset(0, 3))] : null,
              ),
            ),
            SizedBox(height: 4),
            AnimatedOpacity(
              duration: Duration(milliseconds: 200),
              opacity: isSelected ? 1.0 : 0.0,
              child: Container(
                height: 4,
                width: 4,
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
