import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'pages/paged_post_page.dart';
import 'pages/post_detail_page.dart';
import 'pages/post_list_page.dart';

/// Provider untuk konfigurasi navigasi aplikasi berbasis [GoRouter].
///
/// Menyediakan rute:
/// - `/` : Halaman daftar post utama ([PostListPage])
/// - `/post/:id` : Halaman detail post ([PostDetailPage])
/// - `/paged` : Halaman daftar post berpaginasi ([PagedPostPage])
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'posts',
        builder: (context, state) => const PostListPage(),
      ),
      GoRoute(
        path: '/post/:id',
        name: 'post-detail',
        builder: (context, state) {
          final idStr = state.pathParameters['id'];
          final id = int.tryParse(idStr ?? '') ?? 0;
          return PostDetailPage(postId: id);
        },
      ),
      GoRoute(
        path: '/paged',
        name: 'paged-posts',
        builder: (context, state) => const PagedPostPage(),
      ),
    ],
  );
});
