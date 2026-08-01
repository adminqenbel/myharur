import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/translations.dart';
import '../utils/update_manager.dart';
import '../theme.dart';

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateManager.checkUpdate(context);
    });
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
      body: widget.child,
      bottomNavigationBar: isKeyboardOpen
          ? null
          : SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Container(
                height: 64,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: isDark ? Theme.of(context).dividerColor.withOpacity(0.7) : Colors.black.withOpacity(0.05),
                    width: 1,
                  ),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    color: Theme.of(context).colorScheme.surface.withOpacity(isDark ? 0.92 : 0.85),
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
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, int selectedIndex, bool isDark) {
    final bool isSelected = index == selectedIndex;
    final Color activeColor = AppTheme.accent; // Yellow from spec
    final Color inactiveColor = isDark ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6) : AppTheme.textSecondaryLight;
    
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12, 
          vertical: 10
        ),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
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
                size: 26,
              ),
            ),
            if (isSelected) ...[
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: activeColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
