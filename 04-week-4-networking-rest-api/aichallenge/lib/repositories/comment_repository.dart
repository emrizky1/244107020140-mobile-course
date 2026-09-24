import 'package:dio/dio.dart';
import '../models/comment.dart';

/// Repository yang bertanggung jawab untuk berkomunikasi dengan
/// JSONPlaceholder API endpoint `/comments`.
///
/// Pattern Repository memisahkan logika networking dari UI/state,
/// sehingga mudah di-test dan di-maintain.
class CommentRepository {
  /// Instance Dio untuk HTTP requests.
  /// Diterima via constructor (Dependency Injection) agar bisa
  /// di-mock saat testing.
  ///
  /// CATATAN: baseUrl dan timeout sudah dikonfigurasi secara terpusat
  /// di `dioProvider` (comment_provider.dart), sehingga repository
  /// tidak perlu mengatur sendiri — cukup pakai Dio yang sudah di-inject.
  final Dio _dio;

  /// Constructor menerima instance [Dio].
  ///
  /// Dependency Injection memungkinkan kita mengganti Dio asli
  /// dengan mock Dio saat unit testing.
  CommentRepository(this._dio);

  /// Mengambil daftar komentar berdasarkan [postId].
  ///
  /// - Endpoint: GET /comments?postId={postId}
  /// - Timeout: dikonfigurasi terpusat di `dioProvider` (10 detik)
  /// - Return: `List<Comment>` yang sudah di-parse dari JSON
  /// - Throw: [DioException] jika terjadi error jaringan/server
  Future<List<Comment>> fetchComments(int postId) async {
    // Melakukan GET request ke endpoint /comments dengan query parameter.
    // baseUrl & timeout sudah terpusat di BaseOptions Dio (dioProvider),
    // sehingga di sini cukup menggunakan path relatif.
    final response = await _dio.get(
      '/comments',
      queryParameters: {'postId': postId},
    );

    // ============================================================
    // HARDENING: Validasi tipe response sebelum cast
    // ============================================================
    // response.data dari Dio bisa berupa List, Map, atau String
    // tergantung response server. Kita perlu memastikan tipe-nya
    // sebelum melakukan cast, agar tidak crash.
    final data = response.data;

    // Jika response bukan List (misal: server mengembalikan error
    // dalam format {"message": "Not Found"}), kembalikan list kosong.
    if (data is! List) {
      return [];
    }

    // Mapping setiap item JSON ke objek Comment menggunakan fromJson.
    // `.whereType<Map<String, dynamic>>()` memfilter elemen yang valid
    // dan mengabaikan elemen null/malformed — lebih aman dari `.cast()`.
    return data
        .whereType<Map<String, dynamic>>()
        .map((json) => Comment.fromJson(json))
        .toList();
  }
}
