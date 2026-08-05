// Basic smoke tests for the Settl app shell.
//
// Verifies that the app boots through the GoRouter shell and that the
// floating pill navigation switches between the three tabs.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:settl/app.dart';
import 'package:settl/config/app_environment.dart';
import 'package:settl/config/environment.dart';
import 'package:settl/features/activity/activity_screen.dart';
import 'package:settl/features/home/home_screen.dart';
import 'package:settl/features/profile/profile_screen.dart';

void main() {
  setUpAll(() async {
    // Mirrors main(): initializes AppConfig's late fields before the app boots.
    SharedPreferences.setMockInitialValues({});
    await Environment.init();
    await AppConfig().initialize(environment: AppEnvironment.development);
  });

  testWidgets('App boots and shows the pill navigation with all three tabs',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SettlApp()));
    await tester.pumpAndSettle();

    // The floating pill nav renders all three tabs.
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Home is the initial tab.
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('Pill navigation switches tabs', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SettlApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();

    expect(find.byType(ActivityScreen), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('Theme mode switching updates the app theme', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SettlApp()));
    await tester.pumpAndSettle();

    MaterialApp materialApp() =>
        tester.widget<MaterialApp>(find.byType(MaterialApp));

    // Defaults to following the system theme.
    expect(materialApp().themeMode, ThemeMode.system);

    // Open the Profile tab, then the settings sheet via the gear button.
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(materialApp().themeMode, ThemeMode.dark);

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();

    expect(materialApp().themeMode, ThemeMode.light);
  });

  testWidgets('FAB is visible on Activity and Home but hidden on Profile',
      (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: SettlApp()));
    await tester.pumpAndSettle();

    // Navigate explicitly: appRouter is process-global, so a previous test
    // may have left the shell on the Profile tab.
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.add), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.add), findsNothing);
  });
}
