import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/activity/activity_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/destinations/feature_destination_screen.dart';
import '../features/home/home_screen.dart';
import '../features/navigation/shell.dart';
import '../features/profile/profile_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

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
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
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
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/activity',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ActivityScreen(),
              ),
            ),
          ],
        ),
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
    // These feature routes are opened from Home and intentionally sit outside
    // the three primary tabs. Back returns the user to Home.
    GoRoute(
      path: '/groups',
      builder: (context, state) => const FeatureDestinationScreen(
        title: 'Groups',
        icon: Icons.groups_2_outlined,
        description: 'Shared groups and their expenses will live here.',
      ),
    ),
    GoRoute(
      path: '/budget',
      builder: (context, state) => const FeatureDestinationScreen(
        title: 'Budgets',
        icon: Icons.account_balance_wallet_outlined,
        description: 'Create budgets and track spending by category here.',
      ),
    ),
  ],
);
