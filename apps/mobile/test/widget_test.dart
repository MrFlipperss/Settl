// Basic smoke tests for the Settl app shell.
//
// Verifies that the app boots through the GoRouter shell and that the
// bottom navigation switches between the five tabs.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:settl/app.dart';
import 'package:settl/config/app_environment.dart';
import 'package:settl/config/environment.dart';
import 'package:settl/features/home/home_screen.dart';
import 'package:settl/features/groups/groups_screen.dart';

void main() {
  setUpAll(() async {
    // Mirrors main(): initializes AppConfig's late fields before the app boots.
    SharedPreferences.setMockInitialValues({});
    await Environment.init();
    await AppConfig().initialize(environment: AppEnvironment.development);
  });

  testWidgets('App boots and shows the navigation shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SettlApp()));
    await tester.pumpAndSettle();

    // The shell renders the bottom navigation bar with all five tabs.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Groups'), findsOneWidget);
    expect(find.text('Spotlight'), findsOneWidget);
    expect(find.text('Budget'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Home is the initial tab.
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('Bottom navigation switches tabs', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SettlApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Groups'));
    await tester.pumpAndSettle();

    expect(find.byType(GroupsScreen), findsOneWidget);
  });
}
