import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../data/api_client.dart';
import '../data/models/post.dart';
import '../data/repositories/cached_post_repository.dart';
import '../data/repositories/note_repository.dart';
import '../data/repositories/post_repository.dart';
import '../data/sync.dart';

// -- Dio --
final dioProvider = Provider<Dio>((ref) => createDio());

// -- Repositories --
final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepository(ref.watch(dioProvider)),
);
final cachedPostRepositoryProvider = Provider<CachedPostRepository>(
  (ref) => CachedPostRepository(),
);
final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepository(),
);

// -- Force-offline toggle --
final forceOfflineProvider = NotifierProvider<ForceOfflineNotifier, bool>(
  ForceOfflineNotifier.new,
);

class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle(bool value) => state = value;
}

// -- Cache-first posts --
final postsProvider = AsyncNotifierProvider<PostsNotifier, List<Post>>(
  PostsNotifier.new,
);

class PostsNotifier extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() => _loadCacheFirst();

  Future<List<Post>> _loadCacheFirst() async {
    final cachedRepo = ref.read(cachedPostRepositoryProvider);
    final cached = await loadPostsCacheFirst(cachedRepo);
    // Kick off a background refresh (don't await it).
    _refreshInBackground();
    return cached;
  }

  Future<void> _refreshInBackground() async {
    final isOffline = ref.read(forceOfflineProvider);
    if (isOffline) return;
    final postRepo = ref.read(postRepositoryProvider);
    final cachedRepo = ref.read(cachedPostRepositoryProvider);
    final fresh = await refreshPostsFromNetwork(postRepo, cachedRepo);
    if (fresh != null) {
      state = AsyncData(fresh);
    }
  }

  /// Manually trigger a refresh (e.g. pull-to-refresh).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadCacheFirst);
  }
}

// -- Dirty-note count (for badge) --
final dirtyCountProvider = FutureProvider<int>((ref) {
  return ref.watch(noteRepositoryProvider).countDirty();
});

// -- Notes list --
final notesListProvider = FutureProvider<List>((ref) {
  return ref.watch(noteRepositoryProvider).fetchNotes();
});

// -- Sync action --
final syncNotesProvider = FutureProvider.autoDispose<int>((ref) {
  return syncNotes(ref.read(noteRepositoryProvider));
});
