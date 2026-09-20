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

/// Fixed height of the floating navigation dock pill.
const double _floatingBarHeight = 70.0;

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

  // Drag state: Offset relative to the resting position (Offset.zero = default dock)
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  Offset? _dragStartGlobal;
  Offset? _dragStartOffset;

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

  void _startDrag(Offset globalPosition) {
    HapticFeedback.lightImpact();
    setState(() {
      _isDragging = true;
      _dragStartGlobal = globalPosition;
      _dragStartOffset = _dragOffset;
    });
  }

  void _updateDrag(
    Offset globalPosition,
    double screenWidth,
    double screenHeight,
    EdgeInsets safePadding,
    double barWidth,
    double bottomMargin,
  ) {
    if (!_isDragging || _dragStartGlobal == null || _dragStartOffset == null) {
      return;
    }
    final delta = globalPosition - _dragStartGlobal!;
    final rawX = _dragStartOffset!.dx + delta.dx;
    final rawY = _dragStartOffset!.dy + delta.dy;

    // Clamping: ensure capsule stays within bounds
    final defaultLeft = (screenWidth - barWidth) / 2.0;
    final maxUpward = screenHeight - safePadding.top - _floatingBarHeight - bottomMargin - 16.0;

    final clampedX = rawX.clamp(
      16.0 - defaultLeft,
      math.max(16.0 - defaultLeft, screenWidth - barWidth - 16.0 - defaultLeft),
    ).toDouble();
    // delta.dy is negative when dragging up; clamp between -maxUpward and 0
    final clampedY = rawY.clamp(-math.max(0.0, maxUpward), 0.0).toDouble();

    setState(() {
      _dragOffset = Offset(clampedX, clampedY);
    });
  }

  void _endDrag() {
    if (!_isDragging) return;
    HapticFeedback.selectionClick();
    setState(() {
      _isDragging = false;
      _dragStartGlobal = null;
      _dragStartOffset = null;

      // Magnetic snapping:
      // If pulled close to the resting bottom (within 55px), snap back down
      if (_dragOffset.dy.abs() < 55) {
        _dragOffset = Offset.zero;
      } else if (_dragOffset.dx.abs() < 35) {
        // Snap horizontally to center if near center
        _dragOffset = Offset(0, _dragOffset.dy);
      }
    });
  }

  void _resetPosition() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isDragging = false;
      _dragOffset = Offset.zero;
    });
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
    final screenHeight = mediaQuery.size.height;
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

    // Floating capsule geometry
    // Ensure bottomMargin always stays well above gesture bars (at least 38px)
    final bottomMargin = math.max(safePadding.bottom, 24.0) + 14.0;
    final barWidth = math.min(screenWidth - 48.0, 340.0);
    final defaultLeft = (screenWidth - barWidth) / 2.0;

    final currentBottom = bottomMargin - _dragOffset.dy;
    final currentLeft = defaultLeft + _dragOffset.dx;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: pages),
          AnimatedPositioned(
            duration: _isDragging ? Duration.zero : const Duration(milliseconds: 280),
            curve: Curves.easeOutBack,
            bottom: currentBottom,
            left: currentLeft,
            width: barWidth,
            height: _floatingBarHeight,
            child: AnimatedScale(
              scale: _isDragging ? 1.04 : 1.0,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              child: _buildFloatingBar(
                context,
                screenWidth,
                screenHeight,
                safePadding,
                barWidth,
                bottomMargin,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBar(
    BuildContext context,
    double screenWidth,
    double screenHeight,
    EdgeInsets safePadding,
    double barWidth,
    double bottomMargin,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLiquid = ref.watch(liquidGlassEnabledProvider);
    final colorScheme = theme.colorScheme;

    final backgroundColor = isLiquid
        ? (isDark
            ? const Color(0xFF182219).withValues(alpha: 0.78)
            : Colors.white.withValues(alpha: 0.80))
        : (isDark
            ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.92)
            : colorScheme.surface.withValues(alpha: 0.94));

    final borderColor = isDark
        ? Colors.white.withValues(alpha: isLiquid ? 0.25 : 0.16)
        : (isLiquid
            ? Colors.white.withValues(alpha: 0.90)
            : colorScheme.outlineVariant.withValues(alpha: 0.50));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (details) => _startDrag(details.globalPosition),
      onLongPressMoveUpdate: (details) => _updateDrag(
        details.globalPosition,
        screenWidth,
        screenHeight,
        safePadding,
        barWidth,
        bottomMargin,
      ),
      onLongPressEnd: (_) => _endDrag(),
      child: Container(
        height: _floatingBarHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isDragging ? 0.32 : 0.18),
              blurRadius: _isDragging ? 26 : 16,
              offset: _isDragging ? const Offset(0, 10) : const Offset(0, 5),
              spreadRadius: _isDragging ? 2 : 0,
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
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: isLiquid ? 25 : 20,
              sigmaY: isLiquid ? 25 : 20,
            ),
            child: Container(
              height: _floatingBarHeight,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(35),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dedicated drag grip indicator
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (details) => _startDrag(details.globalPosition),
                    onPanUpdate: (details) => _updateDrag(
                      details.globalPosition,
                      screenWidth,
                      screenHeight,
                      safePadding,
                      barWidth,
                      bottomMargin,
                    ),
                    onPanEnd: (_) => _endDrag(),
                    onDoubleTap: _resetPosition,
                    child: Container(
                      height: 12,
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Container(
                        width: 32,
                        height: 3.5,
                        decoration: BoxDecoration(
                          color: colorScheme.onSurface.withValues(alpha: _isDragging ? 0.55 : 0.28),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  // Material 3 NavigationBar inside floating dock
                  Expanded(
                    child: NavigationBarTheme(
                      data: NavigationBarThemeData(
                        backgroundColor: Colors.transparent,
                        surfaceTintColor: Colors.transparent,
                        elevation: 0,
                        height: 52,
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
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                              height: 1.0,
                            );
                          }
                          return TextStyle(
                            fontSize: 10,
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
                        height: 52,
                        selectedIndex: widget.currentIndex,
                        onDestinationSelected: widget.onIndexChanged,
                        destinations: _barDestinations,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
