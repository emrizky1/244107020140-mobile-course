import 'models/post.dart';
import 'repositories/cached_post_repository.dart';
import 'repositories/note_repository.dart';
import 'repositories/post_repository.dart';

/// Cache-first loading: read from local cache, then refresh from network.
/// Returns the cached list immediately; the caller should update the UI
/// again once [refreshPostsInBackground] completes.
Future<List<Post>> loadPostsCacheFirst(CachedPostRepository cachedRepo) async {
  return cachedRepo.readCachedPosts();
}

/// Fetches fresh posts from the API and saves them to the local cache.
/// Returns the fresh list, or null if the network call fails.
Future<List<Post>?> refreshPostsFromNetwork(
  PostRepository postRepo,
  CachedPostRepository cachedRepo,
) async {
  try {
    final fresh = await postRepo.fetchPosts();
    await cachedRepo.saveCachedPosts(fresh);
    return fresh;
  } catch (_) {
    // Network failed — caller should keep serving the cached data.
    return null;
  }
}

/// Simulates syncing dirty notes to a remote server.
/// In a real project, each dirty note would be sent to the REST API,
/// then marked clean on a 2xx response.
Future<int> syncNotes(NoteRepository repo) async {
  final dirtyCount = await repo.countDirty();
  if (dirtyCount == 0) return 0;
  // Simulate upload: in a real project, send each dirty note
  // to the REST API here, then mark it clean on a 2xx response.
  await Future.delayed(const Duration(seconds: 1));
  await repo.markAllSynced();
  return dirtyCount;
}
