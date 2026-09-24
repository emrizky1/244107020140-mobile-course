import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/post.dart';
import 'package:week4_api/widgets/post_tile.dart';

void main() {
  group('PostTile Widget Tests', () {
    const testPost = Post(
      userId: 1,
      id: 42,
      title: 'Judul Post Uji',
      body: 'Isi lengkap dari post uji untuk widget testing.',
    );

    testWidgets('menampilkan ID, title, dan body dengan benar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PostTile(post: testPost),
          ),
        ),
      );

      // Verifikasi ID di CircleAvatar
      expect(find.text('42'), findsOneWidget);
      // Verifikasi title
      expect(find.text('Judul Post Uji'), findsOneWidget);
      // Verifikasi body
      expect(find.text('Isi lengkap dari post uji untuk widget testing.'),
          findsOneWidget);
      // Verifikasi icon trailing
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('memanggil onTap ketika ditekan', (WidgetTester tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PostTile(
              post: testPost,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PostTile));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
