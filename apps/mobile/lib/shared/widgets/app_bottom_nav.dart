import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Glassmorphic bottom navigation bar — used as [Scaffold.bottomNavigationBar]
/// inside the persistent [ShellScaffold].
///
/// [activeIndex]: 0=home, 1=calendar, 2=insights, 3=profile
/// [showInsightDot]: small dot on the insights icon (set by HomeScreen provider)
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.activeIndex,
    required this.navigationShell,
    this.showInsightDot = false,
  });

  final int activeIndex;
  final StatefulNavigationShell navigationShell;
  final bool showInsightDot;

  /// Fixed height — screens use this to add bottom padding to scrollable content.
  static const double height = 96.0;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      // Re-tap on active tab → go to branch initial location (root of tab)
      initialLocation: index == activeIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.circle,
                  isActive: activeIndex == 0,
                  onTap: () => _onTap(0),
                ),
                _NavItem(
                  icon: Icons.calendar_today,
                  isActive: activeIndex == 1,
                  onTap: () => _onTap(1),
                ),
                _NavItem(
                  icon: Icons.bar_chart,
                  isActive: activeIndex == 2,
                  onTap: () => _onTap(2),
                  showDot: showInsightDot,
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  isActive: activeIndex == 3,
                  onTap: () => _onTap(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.showDot = false,
  });

  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            child: icon == Icons.circle
                ? Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive ? Colors.white : Colors.grey.shade600,
                        width: 3,
                      ),
                    ),
                  )
                : Icon(
                    icon,
                    color: isActive ? Colors.white : Colors.grey[600],
                    size: 24,
                  ),
          ),
          if (showDot)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF6366F1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
