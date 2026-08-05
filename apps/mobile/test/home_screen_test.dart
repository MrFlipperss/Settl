// Widget tests for the design Home screen.
//
// Verifies the budget header, spending-by-category card, the search +
// calculator card, the dues list, and the person detail sheet flow.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:settl/app.dart';
import 'package:settl/config/app_environment.dart';
import 'package:settl/config/environment.dart';
import 'package:settl/features/widgets/design_qr_code.dart';

void main() {
  setUpAll(() async {
    // Mirrors main(): initializes AppConfig's late fields before the app boots.
    SharedPreferences.setMockInitialValues({});
    await Environment.init();
    await AppConfig().initialize(environment: AppEnvironment.development);
  });

  testWidgets('Home renders budget header, categories, search and dues',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SettlApp()));
    await tester.pumpAndSettle();

    expect(find.text('August 2024'), findsOneWidget);
    expect(find.text('₹14,280'), findsOneWidget);
    expect(find.text('of ₹20,000 budget'), findsOneWidget);
    expect(find.text('₹5,720 remaining'), findsOneWidget);

    expect(find.text('Spending by category'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Travel'), findsOneWidget);

    expect(find.text('Search expenses…'), findsOneWidget);

    expect(find.text('Dues'), findsOneWidget);
    expect(find.text('Arjun'), findsOneWidget);
    expect(find.text('rahul@okaxis'), findsOneWidget);
  });

  testWidgets('Toggling the calc button reveals the calculator',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SettlApp()));
    await tester.pumpAndSettle();

    expect(find.text('='), findsNothing);

    // The search card's calc toggle is the last bolt icon (the Bills
    // category icon comes earlier in the tree).
    final toggle = find.byIcon(Icons.bolt_outlined).last;
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(find.text('='), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
  });

  testWidgets('Tapping a dues row opens the person sheet with UPI QR flow',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SettlApp()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Priya'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Priya'));
    await tester.pumpAndSettle();

    expect(find.text('Priya owes you'), findsOneWidget);
    expect(find.text('₹1,200'), findsOneWidget);
    expect(find.text('Send UPI QR Code'), findsOneWidget);
    expect(find.byType(DesignQrCode), findsNothing);

    await tester.tap(find.text('Send UPI QR Code'));
    await tester.pumpAndSettle();

    expect(find.byType(DesignQrCode), findsOneWidget);
    expect(find.text('Share QR Code'), findsOneWidget);
    expect(find.text('Settle Up'), findsOneWidget);
  });
}
