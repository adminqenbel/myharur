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
      extendBody: true, // Allows body to flow underneath the transparent nav bar
      body: widget.child,
      bottomNavigationBar: isKeyboardOpen ? null : SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 30,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  color: isDark ? const Color(0xFF16324F).withOpacity(0.7) : Colors.white.withOpacity(0.65),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNavItem(0, Icons.explore, Icons.explore, l(ref, 'Explore'), selectedIndex, isDark, hasBadge: false),
                      _buildNavItem(1, Icons.storefront, Icons.storefront, l(ref, 'Market'), selectedIndex, isDark, hasBadge: false),
                      _buildNavItem(2, Icons.chat_bubble, Icons.chat_bubble, l(ref, 'Chats'), selectedIndex, isDark, hasBadge: true, badgeCount: 8),
                      _buildNavItem(3, Icons.campaign, Icons.campaign, l(ref, 'Report'), selectedIndex, isDark, hasBadge: false),
                      _buildNavItem(4, Icons.settings, Icons.settings, l(ref, 'Settings'), selectedIndex, isDark, hasBadge: false),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData iconOutlined, IconData iconFilled, String label, int selectedIndex, bool isDark, {bool hasBadge = false, int badgeCount = 0}) {
    final bool isSelected = index == selectedIndex;
    final primaryColor = const Color(0xFF007AFF); // iOS blue like in image
    
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 24 : 12, 
          vertical: isSelected ? 10 : 12
        ),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? Colors.grey.shade800 : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    isSelected ? iconFilled : iconOutlined,
                    color: isSelected ? primaryColor : (isDark ? Colors.white70 : Colors.black87),
                    size: 26,
                  ),
                ),
                if (hasBadge && !isSelected) // hide badge when selected or adjust logic
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF3B30), // iOS red
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badgeCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? primaryColor : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
