import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/post.dart';
import 'package:week4_api/data/providers.dart';
import 'package:week4_api/data/repositories/post_repository.dart';
import 'package:week4_api/main.dart';

class FakePostRepository implements PostRepository {
  @override
  Future<List<Post>> fetchPosts() async => [];

  @override
  Future<List<Post>> fetchPostsPage({required int page, int limit = 10}) async =>
      [];

  @override
  Future<Post> fetchPost(int id) async => const Post(
        userId: 1,
        id: 1,
        title: 'Title',
        body: 'Body',
      );
}

void main() {
  testWidgets('App smoke test - renders Posts API title',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postRepositoryProvider.overrideWithValue(FakePostRepository()),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Posts API'), findsOneWidget);
  });
}
