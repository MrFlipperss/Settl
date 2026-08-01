import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/home/home_screen.dart';
import '../features/groups/groups_screen.dart';
import '../features/spotlight/spotlight_screen.dart';
import '../features/budget/budget_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/navigation/shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(
          // The navigationShell is the single source of truth for the active
          // tab index. The shell mirrors it into selectedIndexProvider so
          // non-GoRouter consumers can react to tab changes.
          currentIndex: navigationShell.currentIndex,
          onIndexChanged: (int newIndex) {
            // Switch to the branch, resetting its stack when the tab is
            // tapped again while already active.
            navigationShell.goBranch(
              newIndex,
              initialLocation: newIndex == navigationShell.currentIndex,
            );
          },
        );
      },
      branches: [
        // Home tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: HomeScreen(),
              ),
            ),
          ],
        ),
        // Groups tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/groups',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: GroupsScreen(),
              ),
            ),
          ],
        ),
        // Spotlight tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/spotlight',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: SpotlightScreen(),
              ),
            ),
          ],
        ),
        // Budget tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/budget',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: BudgetScreen(),
              ),
            ),
          ],
        ),
        // Profile tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ProfileScreen(),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
