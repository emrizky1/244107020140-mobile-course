import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'api_client.dart';
import 'models/comment.dart';
import 'models/post.dart';
import 'repositories/comment_repository.dart';
import 'repositories/post_repository.dart';

export 'network_errors.dart';

final dioProvider = Provider<Dio>((ref) => createDio());

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepository(ref.watch(dioProvider)),
);

class PostListNotifier extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() async {
    // Exception dari repository otomatis menjadi AsyncError.
    // Inilah ekuivalen deklaratif dari AsyncValue.guard di versi lama.
    final repository = ref.watch(postRepositoryProvider);
    return repository.fetchPosts();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(postRepositoryProvider);
      state = AsyncData(await repository.fetchPosts());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final postListProvider =
    AsyncNotifierProvider<PostListNotifier, List<Post>>(
        PostListNotifier.new,
        // Nonaktifkan retry otomatis Riverpod 3 agar error langsung
        // final dan mudah diuji (tanpa ini, future provider di-test
        // akan me-retry dan menggantung).
        retry: (retryCount, error) => null);

/// Helper khusus testing (letakkan di providers.dart): membaca state
/// pertama yang bukan loading lewat listener + completer, sehingga
/// test tidak menunggu retry dan tidak melakukan HTTP sungguhan.
Future<List<Post>> readPostsOnce(ProviderContainer container) {
  final completer = Completer<List<Post>>();
  final sub = container.listen<AsyncValue<List<Post>>>(
    postListProvider,
    (previous, next) {
      if (next.isLoading || completer.isCompleted) return;
      next.whenData(completer.complete);
      if (next.hasError) {
        completer.completeError(
          next.error ?? StateError('unknown error'),
          next.stackTrace ?? StackTrace.empty,
        );
      }
    },
    fireImmediately: true,
  );
  return completer.future.whenComplete(sub.close);
}

Future<Object?> readPostsErrorOnce(ProviderContainer container) {
  final completer = Completer<Object?>();
  final sub = container.listen<AsyncValue<List<Post>>>(
    postListProvider,
    (previous, next) {
      if (next.isLoading || completer.isCompleted) return;
      completer.complete(next.error);
    },
    fireImmediately: true,
  );
  return completer.future.whenComplete(sub.close);
}

// ---------------------------------------------------------------------------
// Comment layer — Repository + AsyncNotifier + helpers
// ---------------------------------------------------------------------------

/// Provider singleton untuk [CommentRepository].
///
/// Menggunakan [Dio] yang sama dari [dioProvider], sehingga baseUrl dan
/// timeout tetap terpusat di [createDio].
final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(ref.watch(dioProvider)),
);

/// AsyncNotifier yang mengambil komentar untuk sebuah post.
///
/// Menggunakan `family`-style pattern Riverpod 3: `postId` diinject
/// melalui factory function saat provider dibuild. Notifier tetap
/// meng-extend [AsyncNotifier], bukan FamilyAsyncNotifier.
///
/// Jika [build] melempar exception (misal DioException), Riverpod
/// otomatis membungkusnya dalam [AsyncError] — tidak perlu try-catch
/// manual di build.
class CommentListNotifier extends AsyncNotifier<List<Comment>> {
  /// postId diinject oleh factory function di provider family.
  CommentListNotifier(this._postId);
  final int _postId;

  @override
  Future<List<Comment>> build() async {
    // Ambil repository dari provider tree.
    final repository = ref.watch(commentRepositoryProvider);
    // Panggil fetchComments; exception otomatis menjadi AsyncError.
    return repository.fetchComments(_postId);
  }

  /// Refresh data komentar secara manual (misal pull-to-refresh).
  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(commentRepositoryProvider);
      state = AsyncData(await repository.fetchComments(_postId));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// Provider family yang menghasilkan daftar komentar berdasarkan [postId].
///
/// Penggunaan di UI:
/// ```dart
/// final commentsAsync = ref.watch(commentListProvider(postId));
/// ```
///
/// Factory `(postId) => CommentListNotifier(postId)` menerima arg dari
/// family dan menginject ke notifier.
///
/// [retry: null] menonaktifkan retry otomatis Riverpod 3 agar error
/// langsung final — penting untuk testing agar tidak menggantung.
final commentListProvider = AsyncNotifierProvider.family<CommentListNotifier,
    List<Comment>, int>(
  (postId) => CommentListNotifier(postId),
  retry: (retryCount, error) => null,
);

/// Helper testing: membaca state pertama non-loading untuk komentar.
Future<List<Comment>> readCommentsOnce(
    ProviderContainer container, int postId) {
  final completer = Completer<List<Comment>>();
  final sub = container.listen<AsyncValue<List<Comment>>>(
    commentListProvider(postId),
    (previous, next) {
      if (next.isLoading || completer.isCompleted) return;
      next.whenData(completer.complete);
      if (next.hasError) {
        completer.completeError(
          next.error ?? StateError('unknown error'),
          next.stackTrace ?? StackTrace.empty,
        );
      }
    },
    fireImmediately: true,
  );
  return completer.future.whenComplete(sub.close);
}

/// Helper testing: membaca error pertama dari comment provider.
Future<Object?> readCommentsErrorOnce(
    ProviderContainer container, int postId) {
  final completer = Completer<Object?>();
  final sub = container.listen<AsyncValue<List<Comment>>>(
    commentListProvider(postId),
    (previous, next) {
      if (next.isLoading || completer.isCompleted) return;
      completer.complete(next.error);
    },
    fireImmediately: true,
  );
  return completer.future.whenComplete(sub.close);
}

// ---------------------------------------------------------------------------
// Post detail provider
// ---------------------------------------------------------------------------

/// Provider untuk mengambil data detail post berdasarkan [postId].
///
/// Logika pengambilan state:
/// 1. Cek apakah [postListProvider] sudah memiliki data yang telah dimuat
///    dan mengandung post dengan ID terkait. Jika ada, data langsung dikembalikan.
/// 2. Jika belum dimuat di list (misal dibuka langsung via link `/post/:id`),
///    panggil repository [fetchPost] untuk mengambil langsung dari API.
final postDetailProvider = FutureProvider.family<Post, int>((ref, postId) async {
  final postsState = ref.read(postListProvider);
  if (postsState.hasValue) {
    for (final post in postsState.value!) {
      if (post.id == postId) {
        return post;
      }
    }
  }

  final repository = ref.watch(postRepositoryProvider);
  return repository.fetchPost(postId);
});