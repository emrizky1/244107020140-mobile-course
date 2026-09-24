import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/network_errors.dart';

void main() {
  group('friendlyErrorMessage', () {
    test('memetakan connectionTimeout ke pesan timeout', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/posts'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(
        friendlyErrorMessage(error),
        contains('Koneksi lambat atau timeout'),
      );
    });

    test('memetakan sendTimeout ke pesan timeout', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/posts'),
        type: DioExceptionType.sendTimeout,
      );
      expect(
        friendlyErrorMessage(error),
        contains('Koneksi lambat atau timeout'),
      );
    });

    test('memetakan receiveTimeout ke pesan timeout', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/posts'),
        type: DioExceptionType.receiveTimeout,
      );
      expect(
        friendlyErrorMessage(error),
        contains('Koneksi lambat atau timeout'),
      );
    });

    test('memetakan connectionError ke pesan koneksi', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/posts'),
        type: DioExceptionType.connectionError,
      );
      expect(
        friendlyErrorMessage(error),
        contains('Tidak dapat terhubung ke server'),
      );
    });

    test('memetakan 404 badResponse ke pesan data tidak ditemukan', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/posts/999'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/posts/999'),
          statusCode: 404,
        ),
      );
      expect(
        friendlyErrorMessage(error),
        contains('Data tidak ditemukan (404)'),
      );
    });

    test('memetakan 401 dan 403 badResponse ke akses ditolak', () {
      final error401 = DioException(
        requestOptions: RequestOptions(path: '/posts'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/posts'),
          statusCode: 401,
        ),
      );
      expect(
        friendlyErrorMessage(error401),
        contains('Akses ditolak (401)'),
      );

      final error403 = DioException(
        requestOptions: RequestOptions(path: '/posts'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/posts'),
          statusCode: 403,
        ),
      );
      expect(
        friendlyErrorMessage(error403),
        contains('Akses ditolak (403)'),
      );
    });

    test('memetakan status code server error (500) ke server bermasalah', () {
      final error500 = DioException(
        requestOptions: RequestOptions(path: '/posts'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/posts'),
          statusCode: 500,
        ),
      );
      expect(
        friendlyErrorMessage(error500),
        contains('Server bermasalah (500)'),
      );
    });

    test('memetakan non-DioException ke pesan error tak terduga', () {
      final error = Exception('Koneksi database lokal gagal');
      expect(
        friendlyErrorMessage(error),
        contains('Terjadi kesalahan tak terduga'),
      );
    });
  });
}
