// Basic smoke tests for the Settl app shell.
//
// Verifies that the app boots through the GoRouter shell and that the
// bottom navigation switches between the three tabs: Budget, Home, Profile.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:settl/app.dart';
import 'package:settl/config/app_environment.dart';
import 'package:settl/config/environment.dart';
import 'package:settl/features/budget/budget_screen.dart';
import 'package:settl/features/home/home_screen.dart';
import 'package:settl/features/profile/profile_screen.dart';

void main() {
  setUpAll(() async {
    // Mirrors main(): initializes AppConfig's late fields before the app boots.
    SharedPreferences.setMockInitialValues({});
    await Environment.init();
    await AppConfig().initialize(environment: AppEnvironment.development);
  });

  testWidgets('App boots and shows the 3-tab navigation shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SettlApp()));
    await tester.pumpAndSettle();

    // The shell renders the bottom navigation bar with three tabs.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Budget'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Groups'), findsNothing);
    expect(find.text('Spotlight'), findsNothing);

    // Home is the initial middle tab.
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('Bottom navigation switches tabs between Budget, Profile, and Home', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SettlApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Budget'));
    await tester.pumpAndSettle();
    expect(find.byType(BudgetScreen), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);

    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Home'),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
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

    // Tab switching works through the rail.
    await tester.tap(find.descendant(
      of: find.byType(NavigationRail),
      matching: find.text('Budget'),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(BudgetScreen), findsOneWidget);
  });

  testWidgets('Floating bottom bar supports hold-and-drag and repositioning',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SettlApp()));
    await tester.pumpAndSettle();

    final positionedFinder = find.byType(AnimatedPositioned);
    expect(positionedFinder, findsOneWidget);

    final initialTopLeft = tester.getTopLeft(positionedFinder);

    // Drag upwards by 120 pixels using a pan gesture on the top handle area
    final barCenter = tester.getCenter(positionedFinder);
    final handleTop = Offset(barCenter.dx, initialTopLeft.dy + 8);
    await tester.dragFrom(handleTop, const Offset(0, -120));
    await tester.pumpAndSettle();

    final draggedTopLeft = tester.getTopLeft(positionedFinder);
    expect(draggedTopLeft.dy, lessThan(initialTopLeft.dy));

    // Double-tap the dragged handle to reset back to the bottom default dock
    final draggedHandleTop = Offset(
      tester.getCenter(positionedFinder).dx,
      draggedTopLeft.dy + 8,
    );
    await tester.tapAt(draggedHandleTop);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(draggedHandleTop);
    await tester.pumpAndSettle();

    final resetTopLeft = tester.getTopLeft(positionedFinder);
    expect(resetTopLeft.dy, closeTo(initialTopLeft.dy, 1.0));
  });
}
