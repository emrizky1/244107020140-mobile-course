import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/pages/announcement_page.dart';
import 'package:campus_notify/pages/login_page.dart';
import 'package:campus_notify/data/token_store.dart';
import 'package:campus_notify/providers/auth_provider.dart';

class FakeTokenStore extends TokenStore {
  @override
  Future<String?> readAccess() async => null;

  @override
  Future<String?> readRefresh() async => null;
}

void main() {
  testWidgets('AnnouncementPage displays announcement ID',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AnnouncementPage(id: '42'),
      ),
    );

    expect(find.text('Announcement 42'), findsOneWidget);
    expect(find.text('Announcement ID: 42'), findsOneWidget);
  });

  testWidgets('LoginPage renders login fields and button',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStoreProvider.overrideWithValue(FakeTokenStore()),
        ],
        child: const MaterialApp(
          home: LoginPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Campus Notify'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
