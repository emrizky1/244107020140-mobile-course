import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/post.dart';
import 'package:week4_api/data/providers.dart';
import 'package:week4_api/data/repositories/post_repository.dart';

class FakePostRepository implements PostRepository {
  FakePostRepository({
    this.postsToReturn = const [],
    this.postToReturn,
  });

  final List<Post> postsToReturn;
  final Post? postToReturn;
  int fetchPostCallCount = 0;

  @override
  Future<List<Post>> fetchPosts() async => postsToReturn;

  @override
  Future<List<Post>> fetchPostsPage({required int page, int limit = 10}) async =>
      postsToReturn;

  @override
  Future<Post> fetchPost(int id) async {
    fetchPostCallCount++;
    if (postToReturn != null && postToReturn!.id == id) {
      return postToReturn!;
    }
    throw StateError('Post not found');
  }
}

void main() {
  group('postDetailProvider', () {
    const cachedPost = Post(
      userId: 1,
      id: 10,
      title: 'Cached Title',
      body: 'Cached Body',
    );

    const directPost = Post(
      userId: 2,
      id: 99,
      title: 'Direct Fetch Title',
      body: 'Direct Fetch Body',
    );

    test('mengambil post dari postListProvider jika list sudah dimuat', () async {
      final fakeRepo = FakePostRepository(
        postsToReturn: [cachedPost],
        postToReturn: directPost,
      );

      final container = ProviderContainer(
        overrides: [
          postRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      // Muat postListProvider terlebih dahulu
      await readPostsOnce(container);

      // Baca postDetailProvider untuk ID 10
      final result = await container.read(postDetailProvider(10).future);

      expect(result.id, 10);
      expect(result.title, 'Cached Title');
      // Pastikan fetchPost di repository TIDAK dipanggil karena sudah ada di list
      expect(fakeRepo.fetchPostCallCount, 0);
    });

    test(
        'memanggil repository.fetchPost jika post tidak ada di list atau dibuka langsung',
        () async {
      final fakeRepo = FakePostRepository(
        postsToReturn: [cachedPost],
        postToReturn: directPost,
      );

      final container = ProviderContainer(
        overrides: [
          postRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      // Langsung akses postDetailProvider untuk ID 99 (tidak ada di list)
      final result = await container.read(postDetailProvider(99).future);

      expect(result.id, 99);
      expect(result.title, 'Direct Fetch Title');
      // Pastikan repository.fetchPost dipanggil
      expect(fakeRepo.fetchPostCallCount, 1);
    });
  });
}
