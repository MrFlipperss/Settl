import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../home/home_screen.dart';
import '../groups/groups_screen.dart';
import '../spotlight/spotlight_screen.dart';
import '../budget/budget_screen.dart';
import '../profile/profile_screen.dart';

final _screens = <Widget>[
  const HomeScreen(),
  const GroupsScreen(),
  const SpotlightScreen(),
  const BudgetScreen(),
  const ProfileScreen(),
];

final _labels = <String>[
  'Home',
  'Groups',
  'Spotlight',
  'Budget',
  'Profile',
];

final _icons = <IconData>[
  Icons.home_outlined,
  Icons.group_outlined,
  Icons.search_outlined,
  Icons.account_balance_wallet_outlined,
  Icons.person_outline,
];

final _activeIcons = <IconData>[
  Icons.home,
  Icons.group,
  Icons.search,
  Icons.account_balance_wallet,
  Icons.person,
];

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: List.generate(
          _labels.length,
          (i) => NavigationDestination(
            icon: Icon(_icons[i]),
            selectedIcon: Icon(_activeIcons[i]),
            label: _labels[i],
          ),
        ),
      ),
    );
  }
}
