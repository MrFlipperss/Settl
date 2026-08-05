import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../activity/activity_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../sheets/add_expense_sheet.dart';
import '../widgets/app_icon.dart';
import '../widgets/design_sheet.dart';
import '../../providers.dart';
import '../../theme/app_theme.dart';

/// Maximum content width — the design is tuned for a ~430px phone canvas.
const double _contentMaxWidth = 430;

enum ShellTab {
  activity(icon: 'activity', label: 'Activity'),
  home(icon: 'home', label: 'Home'),
  profile(icon: 'profile', label: 'Profile');

  const ShellTab({required this.icon, required this.label});

  final String icon;
  final String label;
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
    this.child,
  });

  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final Widget? child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late final PageController _pageController;

  // Guards against onPageChanged firing when we programmatically jump the
  // PageView (e.g. in didUpdateWidget), which would re-enter goBranch during
  // the build phase and corrupt the Router.
  bool _isProgrammaticJump = false;

  final List<Widget> _screens = const [
    ActivityScreen(),
    HomeScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.currentIndex);
    // Deferred: Riverpod disallows modifying providers during widget
    // lifecycles (build phase). The write runs after the first build.
    Future.microtask(() {
      if (mounted) {
        ref.read(selectedIndexProvider.notifier).state = widget.currentIndex;
      }
    });
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _jumpToPageWithoutAnimation(widget.currentIndex);
      Future.microtask(() {
        if (mounted) {
          ref.read(selectedIndexProvider.notifier).state = widget.currentIndex;
        }
      });
    }
  }

  void _jumpToPageWithoutAnimation(int page) {
    _isProgrammaticJump = true;
    if (_pageController.positions.isNotEmpty) {
      _pageController.jumpToPage(page);
    }
    _isProgrammaticJump = false;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (_isProgrammaticJump) return;
    widget.onIndexChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;

    final pages = PageView(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      children: _screens,
    );

    final body = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
        child: pages,
      ),
    );

    return Scaffold(
      backgroundColor: tokens.bg,
      body: Stack(
        children: [
          body,
          // Floating pill navigation
          Positioned(
            bottom: 20,
            left: 40,
            right: 40,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: _FloatingNav(
                  currentIndex: widget.currentIndex,
                  onSelected: widget.onIndexChanged,
                ),
              ),
            ),
          ),
          // FAB — visible on Activity and Home only
          if (widget.currentIndex != ShellTab.profile.index)
            Positioned(
              bottom: 96,
              right: math.max(
                16,
                (screenWidth - _contentMaxWidth) / 2 + 16,
              ),
              child: _AddExpenseFab(
                onTap: () => DesignSheet.show(
                  context,
                  child: const AddExpenseSheet(),
                  maxHeightFactor: 0.92,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Floating liquid-glass pill: Activity | Home | Profile with drag-to-switch.
class _FloatingNav extends StatefulWidget {
  const _FloatingNav({
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  State<_FloatingNav> createState() => _FloatingNavState();
}

class _FloatingNavState extends State<_FloatingNav> {
  double _accumulatedDelta = 0;

  void _onDragUpdate(DragUpdateDetails details) {
    _accumulatedDelta += details.delta.dx;
    if (_accumulatedDelta.abs() > 52) {
      final direction = _accumulatedDelta < 0 ? 1 : -1;
      final next = widget.currentIndex + direction;
      if (next >= 0 && next < ShellTab.values.length) {
        widget.onSelected(next);
      }
      _accumulatedDelta = 0;
    }
  }

  void _onDragEnd() {
    _accumulatedDelta = 0;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.of(context);
    final width = MediaQuery.sizeOf(context).width;

    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: (_) => _onDragEnd(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            width: math.min(width - 80, 280),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: tokens.navBg,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: tokens.navBorder),
              boxShadow: [
                BoxShadow(
                  color: tokens.shadow,
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1,
                    color: tokens.glassInner,
                  ),
                ),
                Row(
                  children: [
                    for (final tab in ShellTab.values)
                      Expanded(
                        child: _NavButton(
                          tab: tab,
                          selected: tab.index == widget.currentIndex,
                          onTap: () => widget.onSelected(tab.index),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final ShellTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: selected ? tokens.container : Colors.transparent,
              borderRadius: BorderRadius.circular(100),
            ),
            child: AppIcon(
              tab.icon,
              size: 22,
              color: selected ? tokens.primary : tokens.onSurfaceVar,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            tab.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? tokens.primary : tokens.onSurfaceVar,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddExpenseFab extends StatelessWidget {
  const _AddExpenseFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.of(context);
    return Material(
      color: tokens.primary,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: tokens.shadow,
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const AppIcon('plus', size: 24, color: Colors.white),
        ),
      ),
    );
  }
}
