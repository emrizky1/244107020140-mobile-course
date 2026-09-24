import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aichallenge/main.dart';
import 'package:aichallenge/models/comment.dart';
import 'package:aichallenge/providers/comment_provider.dart';

void main() {
  testWidgets('CommentPage menampilkan judul dan dropdown', (tester) async {
    // Override commentProvider agar mengembalikan data dummy
    // tanpa melakukan HTTP call sama sekali.
    // Ini menghindari pending timer dari Dio di test environment.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          commentProvider.overrideWith(() => _FakeCommentNotifier()),
        ],
        child: const MyApp(),
      ),
    );

    // Verifikasi judul AppBar muncul.
    expect(find.text('Komentar Post #1'), findsOneWidget);

    // Verifikasi label dropdown muncul.
    expect(find.text('Pilih Post: '), findsOneWidget);
  });
}

/// Fake notifier yang langsung mengembalikan list kosong
/// tanpa melakukan HTTP request.
class _FakeCommentNotifier extends CommentNotifier {
  @override
  Future<List<Comment>> build() async => [];

  @override
  Future<void> loadComments(int postId) async {
    state = const AsyncValue.data([]);
  }
}
