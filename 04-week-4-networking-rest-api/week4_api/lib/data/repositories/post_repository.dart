import 'package:dio/dio.dart';
import '../models/post.dart';

class PostRepository {
  PostRepository(this._dio);
  final Dio _dio;

  Future<List<Post>> fetchPosts() async {
    final response = await _dio.get<List>('/posts');
    final data = response.data ?? [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Post.fromJson)
        .toList();
  }

  Future<List<Post>> fetchPostsPage({
  required int page,
  int limit = 10,
}) async {
  final response = await _dio.get<List>(
    '/posts',
    queryParameters: {'_page': page, '_limit': limit},
  );
  final data = response.data ?? [];
  return data
      .whereType<Map<String, dynamic>>()
      .map(Post.fromJson)
      .toList();
}

  /// Mengambil satu post berdasarkan [id].
  ///
  /// Memanggil `GET /posts/{id}`.
  /// Digunakan ketika halaman detail dibuka langsung (misal via GoRouter `/post/:id`).
  Future<Post> fetchPost(int id) async {
    final response = await _dio.get('/posts/$id');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return Post.fromJson(data);
    } else if (data is Map) {
      return Post.fromJson(Map<String, dynamic>.from(data));
    }
    throw StateError('Format response tidak valid untuk post $id');
  }
}