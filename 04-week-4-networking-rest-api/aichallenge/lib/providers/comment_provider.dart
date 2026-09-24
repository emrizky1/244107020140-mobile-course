import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/comment.dart';
import '../repositories/comment_repository.dart';

// ============================================================
// PROVIDER SETUP
// ============================================================

/// Provider untuk instance Dio.
///
/// Membuat satu instance Dio yang digunakan di seluruh aplikasi.
/// Semua konfigurasi (baseUrl, timeout) terpusat di sini — satu sumber kebenaran.
final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      // Base URL terpusat — repository cukup menggunakan path relatif.
      baseUrl: 'https://jsonplaceholder.typicode.com',
      // Timeout saat membuka koneksi ke server (10 detik).
      connectTimeout: const Duration(seconds: 10),
      // Timeout saat mengirim data ke server (10 detik).
      sendTimeout: const Duration(seconds: 10),
      // Timeout saat menerima response dari server (10 detik).
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
});

/// Provider untuk CommentRepository.
///
/// Menggunakan `ref.watch(dioProvider)` untuk mendapatkan instance Dio.
/// Jika Dio berubah (misal: di-override saat testing), repository
/// otomatis di-rebuild.
final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepository(ref.watch(dioProvider));
});

// ============================================================
// ASYNC NOTIFIER — State Management untuk daftar komentar
// ============================================================

/// AsyncNotifier yang mengelola state daftar komentar.
///
/// AsyncNotifier dari Riverpod secara otomatis menangani 3 state:
/// - [AsyncLoading] — saat data sedang dimuat.
/// - [AsyncData]    — saat data berhasil dimuat.
/// - [AsyncError]   — saat terjadi error.
///
/// Keuntungan: UI hanya perlu `switch` pada `state` tanpa perlu
/// mengelola loading/error secara manual.
class CommentNotifier extends AutoDisposeAsyncNotifier<List<Comment>> {
  /// Method `build()` dipanggil saat provider pertama kali dibaca.
  /// Mengembalikan Future kosong (belum ada data awal).
  /// Data akan dimuat setelah `loadComments()` dipanggil.
  @override
  Future<List<Comment>> build() async {
    // Mengembalikan list kosong sebagai state awal.
    // Komentar akan dimuat saat user memilih post tertentu.
    return [];
  }

  /// Memuat komentar berdasarkan [postId] dari API.
  ///
  /// Flow:
  /// 1. Set state ke [AsyncLoading] untuk memicu loading indicator di UI.
  /// 2. Panggil repository untuk fetch data.
  /// 3. Jika berhasil → state menjadi [AsyncData] dengan list komentar.
  /// 4. Jika gagal → state menjadi [AsyncError] dengan pesan ramah pengguna.
  Future<void> loadComments(int postId) async {
    // Set state ke loading. Ini akan memicu UI untuk menampilkan
    // loading indicator (CircularProgressIndicator, shimmer, dll).
    state = const AsyncValue.loading();

    // `AsyncValue.guard` otomatis menangkap exception dan mengubahnya
    // menjadi AsyncError. Jika sukses, hasilnya jadi AsyncData.
    state = await AsyncValue.guard(() async {
      try {
        // Mengambil repository dari provider tree.
        final repository = ref.read(commentRepositoryProvider);

        // Memanggil API melalui repository.
        return await repository.fetchComments(postId);
      } on DioException catch (e) {
        // Mengubah DioException menjadi Exception dengan pesan
        // yang ramah pengguna sebelum diteruskan ke AsyncError.
        throw Exception(getUserFriendlyError(e));
      } on SocketException {
        // SocketException terjadi saat tidak ada koneksi internet sama sekali.
        throw Exception(
          'Tidak ada koneksi internet. Periksa jaringan Anda dan coba lagi.',
        );
      }
    });
  }
}

/// Provider untuk CommentNotifier.
///
/// `AutoDispose` berarti state otomatis di-dispose saat tidak ada
/// widget yang mendengarkan, menghemat memori.
final commentProvider =
    AsyncNotifierProvider.autoDispose<CommentNotifier, List<Comment>>(
      CommentNotifier.new,
    );

// ============================================================
// ERROR HANDLING — Pesan error ramah pengguna
// ============================================================

/// Mengonversi [DioException] menjadi pesan error yang mudah dipahami
/// oleh pengguna non-teknis.
///
/// Menangani 4 skenario utama:
/// 1. **Timeout** — koneksi atau penerimaan data terlalu lama.
/// 2. **Connection Error** — tidak bisa terhubung ke server.
/// 3. **404 Not Found** — resource tidak ditemukan.
/// 4. **500 Internal Server Error** — masalah di sisi server.
/// 5. **Lainnya** — error yang tidak terduga.
String getUserFriendlyError(DioException error) {
  switch (error.type) {
    // Timeout saat mencoba membuka koneksi ke server.
    case DioExceptionType.connectionTimeout:
      return 'Koneksi ke server terlalu lama. '
          'Periksa koneksi internet Anda dan coba lagi.';

    // Timeout saat mengirim data ke server.
    case DioExceptionType.sendTimeout:
      return 'Pengiriman data ke server terlalu lama. '
          'Periksa koneksi internet Anda dan coba lagi.';

    // Timeout saat menerima response dari server.
    case DioExceptionType.receiveTimeout:
      return 'Server terlalu lama merespons. '
          'Silakan coba beberapa saat lagi.';

    // Tidak bisa terhubung ke server (DNS gagal, server mati, dll).
    case DioExceptionType.connectionError:
      return 'Tidak dapat terhubung ke server. '
          'Periksa koneksi internet Anda dan coba lagi.';

    // Error dari response HTTP (4xx, 5xx, dll).
    case DioExceptionType.badResponse:
      // Mengambil status code dari response.
      final statusCode = error.response?.statusCode;
      switch (statusCode) {
        case 404:
          // Resource tidak ditemukan — mungkin postId salah.
          return 'Data tidak ditemukan. '
              'Pastikan ID post yang diminta benar.';
        case 500:
          // Server error — bukan salah pengguna.
          return 'Terjadi masalah di server. '
              'Silakan coba beberapa saat lagi.';
        default:
          // Status code lain yang tidak ditangani spesifik.
          return 'Terjadi kesalahan (kode: $statusCode). '
              'Silakan coba lagi.';
      }

    // Request dibatalkan secara manual.
    case DioExceptionType.cancel:
      return 'Permintaan dibatalkan.';

    // Error lain yang tidak masuk kategori di atas.
    case DioExceptionType.badCertificate:
      return 'Sertifikat keamanan server tidak valid. '
          'Hubungi administrator.';

    case DioExceptionType.unknown:
    default:
      return 'Terjadi kesalahan yang tidak terduga. '
          'Silakan coba lagi.';
  }
}
