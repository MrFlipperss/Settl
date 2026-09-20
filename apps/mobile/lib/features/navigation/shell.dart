import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../budget/budget_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../../providers.dart';

/// Minimum width (logical pixels) at which the shell switches from a bottom
/// navigation bar to a side navigation rail (tablets, desktop, web).
const double _railBreakpoint = 840;

/// Height of the floating navigation dock pill.
const double _floatingBarHeight = 64.0;

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

  // Visual feedback state when user is actively holding and scrubbing the bar
  bool _isScrubbing = false;

  // Screens for each tab
  final List<Widget> _screens = const [
    BudgetScreen(),
    HomeScreen(),
    ProfileScreen(),
  ];

  static const List<NavigationDestination> _barDestinations = [
    NavigationDestination(
      icon: Icon(Icons.account_balance_wallet_outlined),
      selectedIcon: Icon(Icons.account_balance_wallet),
      label: 'Budget',
    ),
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  static const List<NavigationRailDestination> _railDestinations = [
    NavigationRailDestination(
      icon: Icon(Icons.account_balance_wallet_outlined),
      selectedIcon: Icon(Icons.account_balance_wallet),
      label: Text('Budget'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: Text('Home'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: Text('Profile'),
    ),
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
      // Deferred: Riverpod disallows modifying providers during widget
      // lifecycles (build phase). The write runs after the current build.
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
    // Ignore page changes triggered by our own programmatic jumps (see
    // _jumpToPageWithoutAnimation); user swipes still propagate to GoRouter.
    if (_isProgrammaticJump) return;
    widget.onIndexChanged(index);
  }

  /// Handles hold-and-drag / scrub gesture across the bottom bar to switch screens.
  void _handleScrubPosition(double localX, double barWidth) {
    if (barWidth <= 0) return;
    // 3 tabs: Budget (0), Home (1), Profile (2)
    final slotWidth = barWidth / 3.0;
    final targetIndex = (localX / slotWidth).floor().clamp(0, 2);

    if (targetIndex != widget.currentIndex) {
      HapticFeedback.selectionClick();
      _isProgrammaticJump = true;
      if (_pageController.positions.isNotEmpty) {
        _pageController.animateToPage(
          targetIndex,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      }
      _isProgrammaticJump = false;
      widget.onIndexChanged(targetIndex);
      ref.read(selectedIndexProvider.notifier).state = targetIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine what pages to show in the PageView
    final List<Widget> effectivePages;
    if (widget.child != null) {
      effectivePages = List.generate(
        _screens.length,
        (index) => index == widget.currentIndex
            ? widget.child!
            : const SizedBox.shrink(),
      );
    } else {
      effectivePages = _screens;
    }

    final pages = PageView(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      children: effectivePages,
    );

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final safePadding = mediaQuery.padding;

    final useRail = screenWidth >= _railBreakpoint;

    if (useRail) {
      return Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NavigationRail(
              selectedIndex: widget.currentIndex,
              onDestinationSelected: widget.onIndexChanged,
              labelType: NavigationRailLabelType.all,
              destinations: _railDestinations,
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: pages),
          ],
        ),
      );
    }

    // Floating bar layout geometry
    // Ensure generous clearance (at least 38px) above system gesture pill
    final bottomMargin = math.max(safePadding.bottom, 24.0) + 14.0;
    final barWidth = math.min(screenWidth - 48.0, 320.0);
    final leftMargin = (screenWidth - barWidth) / 2.0;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: pages),
          Positioned(
            bottom: bottomMargin,
            left: leftMargin,
            width: barWidth,
            height: _floatingBarHeight,
            child: AnimatedScale(
              scale: _isScrubbing ? 1.03 : 1.0,
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              child: _buildFloatingScrubberBar(context, barWidth),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingScrubberBar(BuildContext context, double barWidth) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLiquid = ref.watch(liquidGlassEnabledProvider);
    final colorScheme = theme.colorScheme;

    final backgroundColor = isLiquid
        ? (isDark
            ? const Color(0xFF162017).withValues(alpha: 0.80)
            : Colors.white.withValues(alpha: 0.82))
        : (isDark
            ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.92)
            : colorScheme.surface.withValues(alpha: 0.95));

    final borderColor = isDark
        ? Colors.white.withValues(alpha: isLiquid ? 0.25 : 0.16)
        : (isLiquid
            ? Colors.white.withValues(alpha: 0.90)
            : colorScheme.outlineVariant.withValues(alpha: 0.50));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragDown: (details) {
        setState(() => _isScrubbing = true);
        _handleScrubPosition(details.localPosition.dx, barWidth);
      },
      onHorizontalDragStart: (details) {
        setState(() => _isScrubbing = true);
        _handleScrubPosition(details.localPosition.dx, barWidth);
      },
      onHorizontalDragUpdate: (details) {
        _handleScrubPosition(details.localPosition.dx, barWidth);
      },
      onHorizontalDragEnd: (_) {
        setState(() => _isScrubbing = false);
      },
      onHorizontalDragCancel: () {
        setState(() => _isScrubbing = false);
      },
      child: Container(
        height: _floatingBarHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isScrubbing ? 0.30 : 0.18),
              blurRadius: _isScrubbing ? 24 : 16,
              offset: _isScrubbing ? const Offset(0, 8) : const Offset(0, 4),
              spreadRadius: _isScrubbing ? 1 : 0,
            ),
            if (isLiquid)
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: isLiquid ? 25 : 20,
              sigmaY: isLiquid ? 25 : 20,
            ),
            child: Container(
              height: _floatingBarHeight,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  height: _floatingBarHeight,
                  indicatorColor: colorScheme.secondaryContainer.withValues(alpha: 0.8),
                  iconTheme: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return IconThemeData(
                        size: 22,
                        color: colorScheme.primary,
                      );
                    }
                    return IconThemeData(
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    );
                  }),
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                        height: 1.0,
                      );
                    }
                    return TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.normal,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.0,
                    );
                  }),
                ),
                child: NavigationBar(
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  height: _floatingBarHeight,
                  selectedIndex: widget.currentIndex,
                  onDestinationSelected: widget.onIndexChanged,
                  destinations: _barDestinations,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
