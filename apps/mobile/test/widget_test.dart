// Basic smoke tests for the Settl app shell.
//
// Verifies that the app boots through the GoRouter shell and that the
// navigation switches between the three tabs: Home, Activity, Profile.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:settl/app.dart';
import 'package:settl/config/app_environment.dart';
import 'package:settl/features/activity/activity_screen.dart';
import 'package:settl/features/home/home_screen.dart';
import 'package:settl/features/profile/profile_screen.dart';

void main() {
  setUpAll(() async {
    // Mirrors main(): initializes AppConfig's late fields before the app boots.
    await AppConfig().initialize(environment: AppEnvironment.development);
  });

  testWidgets('App boots and shows the 3-tab navigation shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SettlApp()));
    await tester.pumpAndSettle();

    // The shell renders the three primary tabs in their current order.
    expect(find.byType(NavigationBar), findsOneWidget);
    final navigationBarFinder = find.byType(NavigationBar);
    final navigationBar = tester.widget<NavigationBar>(navigationBarFinder);
    for (final label in ['Home', 'Activity', 'Profile']) {
      expect(
        find.descendant(
          of: navigationBarFinder,
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }

    // Home is the first and initial tab.
    expect(navigationBar.selectedIndex, 0);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('Bottom navigation switches between Home, Activity, and Profile',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SettlApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();
    expect(find.byType(ActivityScreen), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );

    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Home'),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });

  testWidgets('Theme mode switching updates the app theme', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SettlApp()));
    await tester.pumpAndSettle();

    MaterialApp materialApp() =>
        tester.widget<MaterialApp>(find.byType(MaterialApp));

    // Defaults to following the system theme.
    expect(materialApp().themeMode, ThemeMode.system);

    // Open the Profile tab, where the appearance selector lives.
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(materialApp().themeMode, ThemeMode.dark);

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();

    expect(materialApp().themeMode, ThemeMode.light);
  });

  testWidgets('Wide layouts use a navigation rail instead of the bottom bar',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: SettlApp()));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    // Tab switching works through the rail and follows the same order.
    await tester.tap(find.descendant(
      of: find.byType(NavigationRail),
      matching: find.text('Activity'),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(ActivityScreen), findsOneWidget);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      1,
    );
  });
}
