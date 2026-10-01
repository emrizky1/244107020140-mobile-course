
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:week5_offline_notes/main.dart';

void main() {
  testWidgets('App renders with bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    // Verify bottom navigation destinations are present.
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Posts'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Verify the Notes page title is shown by default.
    expect(find.text('Offline Notes'), findsOneWidget);
  });

  testWidgets('Can switch tabs via bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    // Tap on Settings tab.
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Dark Mode'), findsOneWidget);
    expect(find.text('Force Offline'), findsOneWidget);
  });
}
