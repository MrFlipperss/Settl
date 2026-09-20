import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/auth/forgot_password_screen.dart';
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
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(
          currentIndex: navigationShell.currentIndex,
          onIndexChanged: (int newIndex) {
            navigationShell.goBranch(
              newIndex,
              initialLocation: newIndex == navigationShell.currentIndex,
            );
          },
        );
      },
      branches: [
        // Index 0: Home
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
        // Index 1: Groups
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
        // Index 2: Spotlight
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
        // Index 3: Budget
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
        // Index 4: Profile
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

