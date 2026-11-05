import 'package:campus_notify/features/chat/domain/repositories/ai_repository.dart';
import 'package:campus_notify/features/chat/presentation/pages/chat_screen.dart';
import 'package:campus_notify/features/chat/presentation/providers/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAiRepository implements AiRepository {
  @override
  @override
  String? cachedAnswer(String question) => null;

  @override
  Stream<String> ask(String question) async* {
    yield 'Halo';
  }

  @override
  Future<void> saveApiKey(String key) async {}
}

void main() {
  testWidgets('saving an API key closes the dialog without a framework error', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiRepositoryProvider.overrideWithValue(_FakeAiRepository()),
        ],
        child: const MaterialApp(home: ChatScreen()),
      ),
    );

    await tester.tap(find.byTooltip('Pengaturan API key'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'dummy-test-value');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Pengaturan AI'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
