import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../home/home_screen.dart';
import '../groups/groups_screen.dart';
import '../spotlight/spotlight_screen.dart';
import '../budget/budget_screen.dart';
import '../profile/profile_screen.dart';
import '../../providers.dart';

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

  // Screens for each tab
  final List<Widget> _screens = const [
    HomeScreen(),
    GroupsScreen(),
    SpotlightScreen(),
    BudgetScreen(),
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

  @override
  Widget build(BuildContext context) {
    // Determine what pages to show in the PageView
    final List<Widget> effectivePages;
    if (widget.child != null) {
      // If a custom child is provided, show it at the current index
      // and placeholder pages for other indices
      effectivePages = List.generate(
        _screens.length,
        (index) => index == widget.currentIndex
            ? widget.child!
            : const SizedBox.shrink(), // Empty placeholder
      );
    } else {
      // Otherwise, show the standard tabs
      effectivePages = _screens;
    }

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: effectivePages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.currentIndex,
        onDestinationSelected: widget.onIndexChanged,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Groups',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search),
            label: 'Spotlight',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Budget',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}