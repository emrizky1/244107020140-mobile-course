import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/comment.dart';

/// Unit test untuk Comment.fromJson.
///
/// Menguji 3 skenario:
/// 1. Happy path — semua field ada dan valid.
/// 2. Field hilang — JSON kosong {}, fromJson harus fallback ke default.
/// 3. Edge case — tipe data tak terduga (num untuk String, null eksplisit).
void main() {
  group('Comment.fromJson', () {
    // -----------------------------------------------------------------------
    // Test 1: Happy path — semua field lengkap
    // -----------------------------------------------------------------------
    test('mem-parse JSON lengkap dengan benar', () {
      final json = {
        'postId': 1,
        'id': 5,
        'name': 'vero eaque aliquid doloribus',
        'email': 'Hayden@althea.biz',
        'body': 'harum non quasi et ratione',
      };

      final comment = Comment.fromJson(json);

      expect(comment.postId, 1);
      expect(comment.id, 5);
      expect(comment.name, 'vero eaque aliquid doloribus');
      expect(comment.email, 'Hayden@althea.biz');
      expect(comment.body, 'harum non quasi et ratione');
    });

    // -----------------------------------------------------------------------
    // Test 2: Semua field hilang — JSON kosong {}
    // -----------------------------------------------------------------------
    test('mengembalikan default value saat semua field hilang', () {
      // Simulasi response JSON yang tidak mengandung field apapun.
      // fromJson harus tetap aman dan tidak crash.
      final comment = Comment.fromJson(<String, dynamic>{});

      expect(comment.postId, 0, reason: 'postId harus default ke 0');
      expect(comment.id, 0, reason: 'id harus default ke 0');
      expect(comment.name, '', reason: 'name harus default ke string kosong');
      expect(comment.email, '', reason: 'email harus default ke string kosong');
      expect(comment.body, '', reason: 'body harus default ke string kosong');
    });

    // -----------------------------------------------------------------------
    // Test 3: Sebagian field hilang — hanya postId dan name ada
    // -----------------------------------------------------------------------
    test('menangani JSON dengan sebagian field hilang', () {
      final json = <String, dynamic>{
        'postId': 42,
        'name': 'partial data',
        // id, email, body tidak ada
      };

      final comment = Comment.fromJson(json);

      expect(comment.postId, 42);
      expect(comment.id, 0, reason: 'id hilang, harus default 0');
      expect(comment.name, 'partial data');
      expect(comment.email, '', reason: 'email hilang, harus default kosong');
      expect(comment.body, '', reason: 'body hilang, harus default kosong');
    });

    // -----------------------------------------------------------------------
    // Test 4 (Edge case tambahan): field bernilai null eksplisit
    // -----------------------------------------------------------------------
    test('menangani field dengan nilai null eksplisit', () {
      // Server mungkin mengirim field dengan value null alih-alih
      // tidak menyertakan field sama sekali.
      final json = <String, dynamic>{
        'postId': null,
        'id': null,
        'name': null,
        'email': null,
        'body': null,
      };

      final comment = Comment.fromJson(json);

      expect(comment.postId, 0);
      expect(comment.id, 0);
      expect(comment.name, '');
      expect(comment.email, '');
      expect(comment.body, '');
    });

    // -----------------------------------------------------------------------
    // Test 5 (Edge case tambahan): tipe data tak terduga
    // -----------------------------------------------------------------------
    test('menangani postId/id bertipe double dari JSON decoder', () {
      // JSON decoder kadang mengembalikan num (double) untuk angka,
      // `as num?` + `.toInt()` harus menangani ini.
      final json = <String, dynamic>{
        'postId': 3.0,
        'id': 7.0,
        'name': 'test',
        'email': 'a@b.com',
        'body': 'lorem ipsum',
      };

      final comment = Comment.fromJson(json);

      expect(comment.postId, 3);
      expect(comment.id, 7);
    });

    // -----------------------------------------------------------------------
    // Test 6: toJson round-trip
    // -----------------------------------------------------------------------
    test('toJson menghasilkan Map yang bisa di-parse ulang', () {
      final original = Comment(
        postId: 10,
        id: 20,
        name: 'Round Trip',
        email: 'round@trip.com',
        body: 'test body',
      );

      // Serialize lalu deserialize, hasilnya harus identik.
      final roundTripped = Comment.fromJson(original.toJson());

      expect(roundTripped, original);
    });

    // -----------------------------------------------------------------------
    // Test 7: equality
    // -----------------------------------------------------------------------
    test('dua Comment dengan field identik harus equal', () {
      final a = Comment(
        postId: 1,
        id: 2,
        name: 'x',
        email: 'y',
        body: 'z',
      );
      final b = Comment(
        postId: 1,
        id: 2,
        name: 'x',
        email: 'y',
        body: 'z',
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
