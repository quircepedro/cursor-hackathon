import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/app_bottom_nav.dart';

/// Persistent shell with a fixed [AppBottomNav] and smooth tab fade transitions.
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        activeIndex: navigationShell.currentIndex,
        navigationShell: navigationShell,
      ),
    );
  }
}

/// Replaces the default [IndexedStack] with a fade-in animation on each
/// tab switch. State of each branch is preserved (all children stay mounted).
class AnimatedTabShell extends StatefulWidget {
  const AnimatedTabShell({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  State<AnimatedTabShell> createState() => _AnimatedTabShellState();
}

class _AnimatedTabShellState extends State<AnimatedTabShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
      value: 1.0, // start fully visible — no flash on first build
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(AnimatedTabShell old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: IndexedStack(
        index: widget.currentIndex,
        children: widget.children,
      ),
    );
  }
}
