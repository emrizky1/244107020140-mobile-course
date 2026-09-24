import 'package:dio/dio.dart';
import '../models/comment.dart';

/// Repository yang menangani komunikasi dengan endpoint komentar.
///
/// Semua akses HTTP terpusat di sini — UI **tidak boleh** memanggil [Dio]
/// secara langsung. Ini memudahkan testing (cukup mock [Dio]) dan menjaga
/// separation of concerns.
class CommentRepository {
  /// Menerima instance [Dio] yang sudah dikonfigurasi (baseUrl, timeout)
  /// melalui dependency injection, sehingga konfigurasi terpusat di
  /// satu tempat ([createDio] di api_client.dart).
  CommentRepository(this._dio);
  final Dio _dio;

  /// Mengambil daftar komentar untuk post tertentu.
  ///
  /// Memanggil `GET /comments?postId={postId}`.
  ///
  /// Timeout sudah dikonfigurasi secara terpusat di [Dio.BaseOptions]
  /// (10 detik untuk connect dan receive), sehingga tidak perlu diatur
  /// ulang di sini.
  ///
  /// Jika terjadi error (timeout, connection error, bad response),
  /// [DioException] akan dilempar dan ditangani oleh provider layer
  /// melalui [friendlyErrorMessage].
  Future<List<Comment>> fetchComments(int postId) async {
    // Kirim GET request dengan query parameter postId.
    // Generic type <List> memastikan response.data diparse sebagai List.
    final response = await _dio.get<List>(
      '/comments',
      queryParameters: {'postId': postId},
    );

    // Jika response.data null (misal server mengembalikan body kosong),
    // gunakan list kosong sebagai fallback.
    final data = response.data ?? [];

    // Filter hanya elemen bertipe Map<String, dynamic> untuk keamanan tipe,
    // lalu map ke model Comment menggunakan factory fromJson.
    return data
        .whereType<Map<String, dynamic>>()
        .map(Comment.fromJson)
        .toList();
  }
}
