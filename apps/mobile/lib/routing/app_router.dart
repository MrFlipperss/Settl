import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/activity/activity_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/complete_profile_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/destinations/feature_destination_screen.dart';
import '../features/home/home_screen.dart';
import '../features/groups/groups_screen.dart';
import '../features/expenses/add_expense_screen.dart';
import '../features/expenses/expense_detail_screen.dart';
import '../features/contacts/contacts_screen.dart';
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
      path: '/complete-profile',
      builder: (context, state) => const CompleteProfileScreen(),
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
      builder: (context, state) => const GroupsScreen(),
    ),
    GoRoute(
      path: '/expenses/new',
      builder: (context, state) => const AddExpenseScreen(),
    ),
    GoRoute(
      path: '/expenses/:expenseId',
      builder: (context, state) => ExpenseDetailScreen(
        expenseId: state.pathParameters['expenseId']!,
      ),
    ),
    GoRoute(
      path: '/contacts',
      builder: (context, state) => const ContactsScreen(),
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
