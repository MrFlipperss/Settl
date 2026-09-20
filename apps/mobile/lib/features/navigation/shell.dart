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

/// Estimated height of the floating navigation bar capsule.
const double _floatingBarHeight = 78.0;

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

  // Drag & float state for the floating navigation bar
  Offset? _dragPosition;
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

  void _startDrag(Offset globalPosition, double defaultLeft, double defaultTop) {
    HapticFeedback.lightImpact();
    setState(() {
      _isDragging = true;
      _dragStartGlobal = globalPosition;
      _dragStartOffset = _dragPosition ?? Offset(defaultLeft, defaultTop);
    });
  }

  void _updateDrag(
    Offset globalPosition,
    double screenWidth,
    double screenHeight,
    EdgeInsets safePadding,
    double barWidth,
  ) {
    if (!_isDragging || _dragStartGlobal == null || _dragStartOffset == null) {
      return;
    }
    final delta = globalPosition - _dragStartGlobal!;
    final raw = _dragStartOffset! + delta;
    setState(() {
      _dragPosition = _clampPosition(
        raw,
        screenWidth,
        screenHeight,
        safePadding,
        barWidth,
      );
    });
  }

  void _endDrag(double defaultLeft, double defaultTop) {
    if (!_isDragging) return;
    HapticFeedback.selectionClick();
    setState(() {
      _isDragging = false;
      _dragStartGlobal = null;
      _dragStartOffset = null;
      if (_dragPosition != null) {
        // Snapping heuristics:
        // 1. If released close to bottom, magnetically dock to default bottom
        if ((_dragPosition!.dy - defaultTop).abs() < 64) {
          _dragPosition = Offset(defaultLeft, defaultTop);
        } else if ((_dragPosition!.dx - defaultLeft).abs() < 40) {
          // 2. If near horizontal center, snap horizontally to center
          _dragPosition = Offset(defaultLeft, _dragPosition!.dy);
        }
      }
    });
  }

  void _resetPosition(double defaultLeft, double defaultTop) {
    HapticFeedback.mediumImpact();
    setState(() {
      _isDragging = false;
      _dragPosition = Offset(defaultLeft, defaultTop);
    });
  }

  Offset _clampPosition(
    Offset raw,
    double screenWidth,
    double screenHeight,
    EdgeInsets safePadding,
    double barWidth,
  ) {
    const margin = 12.0;
    const minX = margin;
    final maxX = math.max(minX, screenWidth - barWidth - margin);
    final minY = safePadding.top + margin;
    final maxY = math.max(minY, screenHeight - safePadding.bottom - _floatingBarHeight - margin);

    return Offset(
      raw.dx.clamp(minX, maxX),
      raw.dy.clamp(minY, maxY),
    );
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

    // Geometry for the floating navigation capsule
    final barWidth = math.min(screenWidth - 32.0, 380.0);
    final defaultLeft = (screenWidth - barWidth) / 2.0;
    final defaultTop = screenHeight - safePadding.bottom - _floatingBarHeight - 16.0;

    final effectiveOffset = _clampPosition(
      _dragPosition ?? Offset(defaultLeft, defaultTop),
      screenWidth,
      screenHeight,
      safePadding,
      barWidth,
    );

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: pages),
          AnimatedPositioned(
            duration: _isDragging ? Duration.zero : const Duration(milliseconds: 280),
            curve: Curves.easeOutBack,
            left: effectiveOffset.dx,
            top: effectiveOffset.dy,
            width: barWidth,
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
                defaultLeft,
                defaultTop,
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
    double defaultLeft,
    double defaultTop,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLiquid = ref.watch(liquidGlassEnabledProvider);
    final colorScheme = theme.colorScheme;

    final backgroundColor = isLiquid
        ? (isDark
            ? const Color(0xFF1B241C).withValues(alpha: 0.72)
            : Colors.white.withValues(alpha: 0.76))
        : (isDark
            ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.88)
            : colorScheme.surface.withValues(alpha: 0.92));

    final borderColor = isDark
        ? Colors.white.withValues(alpha: isLiquid ? 0.22 : 0.14)
        : (isLiquid
            ? Colors.white.withValues(alpha: 0.85)
            : colorScheme.outlineVariant.withValues(alpha: 0.45));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (details) => _startDrag(details.globalPosition, defaultLeft, defaultTop),
      onLongPressMoveUpdate: (details) => _updateDrag(
        details.globalPosition,
        screenWidth,
        screenHeight,
        safePadding,
        barWidth,
      ),
      onLongPressEnd: (_) => _endDrag(defaultLeft, defaultTop),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isDragging ? 0.28 : 0.16),
              blurRadius: _isDragging ? 28 : 18,
              offset: _isDragging ? const Offset(0, 10) : const Offset(0, 5),
              spreadRadius: _isDragging ? 2 : 0,
            ),
            if (isLiquid)
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.16),
                blurRadius: 16,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: isLiquid ? 24 : 18,
              sigmaY: isLiquid ? 24 : 18,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Grip / Drag handle at top
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (details) => _startDrag(details.globalPosition, defaultLeft, defaultTop),
                    onPanUpdate: (details) => _updateDrag(
                      details.globalPosition,
                      screenWidth,
                      screenHeight,
                      safePadding,
                      barWidth,
                    ),
                    onPanEnd: (_) => _endDrag(defaultLeft, defaultTop),
                    onDoubleTap: () => _resetPosition(defaultLeft, defaultTop),
                    child: Container(
                      height: 16,
                      alignment: Alignment.center,
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.onSurface.withValues(alpha: _isDragging ? 0.45 : 0.22),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  // Material 3 NavigationBar inside the floating pill
                  NavigationBarTheme(
                    data: NavigationBarThemeData(
                      backgroundColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      elevation: 0,
                      height: 56,
                      indicatorColor: colorScheme.secondaryContainer.withValues(alpha: 0.75),
                      labelTextStyle: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          );
                        }
                        return TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.normal,
                          color: colorScheme.onSurfaceVariant,
                        );
                      }),
                    ),
                    child: NavigationBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      selectedIndex: widget.currentIndex,
                      onDestinationSelected: widget.onIndexChanged,
                      destinations: _barDestinations,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
