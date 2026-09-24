import 'package:flutter_test/flutter_test.dart';
import 'package:aichallenge/models/comment.dart';

void main() {
  // Grup test untuk Comment.fromJson
  group('Comment.fromJson', () {
    // -------------------------------------------------------
    // Test utama: fromJson harus aman saat field hilang/null
    // -------------------------------------------------------
    test('harus menggunakan nilai default saat field hilang dari JSON', () {
      // Arrange: JSON yang tidak lengkap — hanya ada field "id".
      // Field lain (postId, name, email, body) sengaja dihilangkan
      // untuk mensimulasikan response API yang tidak konsisten.
      final Map<String, dynamic> jsonTidakLengkap = {
        'id': 42,
        // 'postId' — hilang
        // 'name'   — hilang
        // 'email'  — hilang
        // 'body'   — hilang
      };

      // Act: Parse JSON yang tidak lengkap.
      final comment = Comment.fromJson(jsonTidakLengkap);

      // Assert: Field yang ada harus ter-parse dengan benar.
      expect(comment.id, 42);

      // Assert: Field yang hilang harus menggunakan nilai default.
      // int default → 0, String default → '' (string kosong).
      expect(comment.postId, 0, reason: 'postId hilang, harus default ke 0');
      expect(comment.name, '', reason: 'name hilang, harus default ke ""');
      expect(comment.email, '', reason: 'email hilang, harus default ke ""');
      expect(comment.body, '', reason: 'body hilang, harus default ke ""');
    });

    // Test tambahan: memastikan fromJson bekerja normal dengan JSON lengkap
    test('harus mem-parse JSON lengkap dengan benar', () {
      // Arrange: JSON lengkap sesuai format JSONPlaceholder.
      final Map<String, dynamic> jsonLengkap = {
        'postId': 1,
        'id': 5,
        'name': 'Nama Penguji',
        'email': 'test@example.com',
        'body': 'Ini adalah komentar.',
      };

      // Act
      final comment = Comment.fromJson(jsonLengkap);

      // Assert: Semua field harus sesuai dengan nilai di JSON.
      expect(comment.postId, 1);
      expect(comment.id, 5);
      expect(comment.name, 'Nama Penguji');
      expect(comment.email, 'test@example.com');
      expect(comment.body, 'Ini adalah komentar.');
    });

    // Test tambahan: JSON benar-benar kosong
    test('harus menangani JSON kosong tanpa crash', () {
      // Arrange: Map kosong — tidak ada field sama sekali.
      final Map<String, dynamic> jsonKosong = {};

      // Act
      final comment = Comment.fromJson(jsonKosong);

      // Assert: Semua field harus menggunakan nilai default.
      expect(comment.postId, 0);
      expect(comment.id, 0);
      expect(comment.name, '');
      expect(comment.email, '');
      expect(comment.body, '');
    });
  });

  // ============================================================
  // EDGE CASE TAMBAHAN — Verifikasi manual oleh reviewer
  // ============================================================

  group('Comment.fromJson edge cases', () {
    // Edge case 1: Field bertipe salah (String di tempat int, dll).
    // Ini bisa terjadi jika API berubah atau data korup.
    test('harus fallback ke default saat tipe data salah', () {
      // Arrange: postId dan id dikirim sebagai String, bukan int.
      // name dikirim sebagai int, bukan String.
      final Map<String, dynamic> jsonTipeSalah = {
        'postId': '999',  // String, seharusnya int
        'id': true,       // bool, seharusnya int
        'name': 12345,    // int, seharusnya String
        'email': null,    // eksplisit null
        'body': ['a'],    // List, seharusnya String
      };

      // Act
      final comment = Comment.fromJson(jsonTipeSalah);

      // Assert: Semua field yang tipe-nya salah harus fallback ke default.
      // `as int?` pada String '999' → null → ?? 0
      expect(comment.postId, 0, reason: 'String tidak bisa di-cast ke int');
      expect(comment.id, 0, reason: 'bool tidak bisa di-cast ke int');
      expect(comment.name, '', reason: 'int tidak bisa di-cast ke String');
      expect(comment.email, '', reason: 'null eksplisit harus default ke ""');
      expect(comment.body, '', reason: 'List tidak bisa di-cast ke String');
    });

    // Edge case 2: Field bernilai null secara eksplisit.
    // Berbeda dengan field hilang — di sini key ada tapi value-nya null.
    test('harus menangani nilai null eksplisit di semua field', () {
      final Map<String, dynamic> jsonSemuaNull = {
        'postId': null,
        'id': null,
        'name': null,
        'email': null,
        'body': null,
      };

      final comment = Comment.fromJson(jsonSemuaNull);

      expect(comment.postId, 0);
      expect(comment.id, 0);
      expect(comment.name, '');
      expect(comment.email, '');
      expect(comment.body, '');
    });
  });

  // ============================================================
  // TEST toJson & equality
  // ============================================================

  group('Comment toJson & equality', () {
    test('toJson harus menghasilkan Map yang bisa di-parse balik', () {
      // Arrange: buat Comment, konversi ke JSON, lalu parse kembali.
      const original = Comment(
        postId: 3,
        id: 10,
        name: 'Test',
        email: 'a@b.com',
        body: 'Hello',
      );

      // Act: roundtrip serialization
      final json = original.toJson();
      final restored = Comment.fromJson(json);

      // Assert: objek hasil roundtrip harus sama dengan aslinya.
      expect(restored, original);
    });

    test('dua Comment dengan field sama harus equal', () {
      const a = Comment(postId: 1, id: 2, name: 'X', email: 'Y', body: 'Z');
      const b = Comment(postId: 1, id: 2, name: 'X', email: 'Y', body: 'Z');

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('dua Comment dengan field berbeda harus tidak equal', () {
      const a = Comment(postId: 1, id: 2, name: 'X', email: 'Y', body: 'Z');
      const b = Comment(postId: 1, id: 3, name: 'X', email: 'Y', body: 'Z');

      expect(a, isNot(equals(b)));
    });
  });
}
