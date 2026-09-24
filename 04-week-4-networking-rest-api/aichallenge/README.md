# AI Challenge — Repository Layer JSONPlaceholder Comments

Repository layer Flutter untuk endpoint `GET /comments?postId={id}`
dari JSONPlaceholder menggunakan **Dio** + **flutter_riverpod**.

## Struktur Proyek

```
lib/
├── models/
│   └── comment.dart          # Model Comment + fromJson/toJson
├── repositories/
│   └── comment_repository.dart  # Repository — HTTP via Dio
├── providers/
│   └── comment_provider.dart    # Riverpod providers + error handling
└── main.dart

test/
└── models/
    └── comment_test.dart     # Unit test fromJson + edge cases
```

---

## ✅ AI Verification Checklist

### 1. Apakah UI memanggil Dio secara langsung (dilarang) atau lewat repository?

**✅ PASS — Lewat repository.**

UI tidak pernah menyentuh Dio. Alur pemanggilan:
```
Widget → ref.read(commentProvider.notifier).loadComments(postId)
       → CommentNotifier → ref.read(commentRepositoryProvider)
       → CommentRepository._dio.get(...)
```

Referensi: [`comment_provider.dart` L80-81](lib/providers/comment_provider.dart)

---

### 2. Apakah fromJson aman null, atau masih memakai cast langsung yang bisa crash?

**✅ PASS — Aman null DAN aman tipe.**

**Temuan awal:** Versi pertama menggunakan `as int? ?? 0` yang ternyata
**THROW TypeError** jika value bukan `int` dan bukan `null`
(contoh: `'999' as int?` → TypeError). Ini ditemukan oleh edge case test.

**Perbaikan:** Diganti ke pattern `is int` yang tidak pernah throw:
```dart
postId: json['postId'] is int ? json['postId'] as int : 0,
name:   json['name'] is String ? json['name'] as String : '',
```

**Tambahan:** Response parsing di repository juga di-hardening:
- `response.data` divalidasi dengan `is! List` sebelum diproses.
- `.whereType<Map<String, dynamic>>()` menggantikan `.cast<>()` yang
  bisa crash pada elemen null/malformed.

Referensi: [`comment.dart` L46-62](lib/models/comment.dart),
[`comment_repository.dart` L49-62](lib/repositories/comment_repository.dart)

---

### 3. Apakah semua tipe DioExceptionType dipetakan ke pesan pengguna?

**✅ PASS — Semua 8 tipe DioExceptionType ter-handle.**

| DioExceptionType        | Pesan Bahasa Indonesia                           |
|-------------------------|--------------------------------------------------|
| `connectionTimeout`     | "Koneksi ke server terlalu lama..."              |
| `sendTimeout`           | "Pengiriman data ke server terlalu lama..."      |
| `receiveTimeout`        | "Server terlalu lama merespons..."               |
| `connectionError`       | "Tidak dapat terhubung ke server..."             |
| `badResponse` (404)     | "Data tidak ditemukan..."                        |
| `badResponse` (500)     | "Terjadi masalah di server..."                   |
| `cancel`                | "Permintaan dibatalkan."                         |
| `badCertificate`        | "Sertifikat keamanan server tidak valid..."      |
| `unknown` / `default`   | "Terjadi kesalahan yang tidak terduga..."        |

Ditambah catch `SocketException` untuk offline total.

Referensi: [`comment_provider.dart` L120-177](lib/providers/comment_provider.dart)

---

### 4. Apakah baseUrl/timeout terpusat di satu client, bukan tersebar di tiap method?

**✅ PASS — Terpusat di `dioProvider`.**

**Temuan awal:** Versi pertama memiliki konfigurasi tersebar:
- `baseUrl` hardcoded di `CommentRepository._baseUrl`
- `sendTimeout`/`receiveTimeout` di-set per-request di `Options()`
- `connectTimeout`/`receiveTimeout` juga di `dioProvider`

**Perbaikan:** Semua dikonfigurasi di satu tempat:
```dart
final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    baseUrl: 'https://jsonplaceholder.typicode.com',  // ← terpusat
    connectTimeout: const Duration(seconds: 10),       // ← terpusat
    sendTimeout: const Duration(seconds: 10),          // ← terpusat
    receiveTimeout: const Duration(seconds: 10),       // ← terpusat
  ));
});
```

Repository sekarang hanya menggunakan path relatif (`'/comments'`).

Referensi: [`comment_provider.dart` L17-30](lib/providers/comment_provider.dart)

---

### 5. Apakah test AI benar-benar menguji kasus field hilang, atau hanya happy path?

**✅ PASS — 8 test case mencakup happy path + 5 edge cases.**

| # | Test Case                                | Kategori   |
|---|------------------------------------------|------------|
| 1 | Field hilang dari JSON (hanya `id`)      | Edge case  |
| 2 | JSON lengkap → semua ter-parse benar     | Happy path |
| 3 | JSON kosong `{}` → semua default         | Edge case  |
| 4 | **Tipe data salah** (String/bool/List)   | Edge case  |
| 5 | **Null eksplisit** di semua field        | Edge case  |
| 6 | toJson → fromJson roundtrip              | Integrity  |
| 7 | Equality: field sama → equal             | Edge case  |
| 8 | Equality: field beda → not equal         | Edge case  |

**Catatan:** Test #4 (tipe data salah) **menemukan bug nyata** pada versi
pertama — `as int?` pada String throw TypeError. Bug diperbaiki ke pattern
`is int` yang benar-benar aman.

Referensi: [`comment_test.dart`](test/models/comment_test.dart)

---

### 6. Apakah hasil AI lolos flutter analyze dan flutter test tanpa warning?

**✅ PASS — Zero warnings, zero errors.**

```
$ flutter analyze
Analyzing aichallenge...
No issues found! (ran in 1.6s)

$ flutter test
00:00 +9: All tests passed!
```

**Temuan awal:** Versi pertama memiliki 1 info warning
(`unintended_html_in_doc_comment`) karena `List<Comment>` di doc comment
tanpa backtick. Sudah diperbaiki.

---

## Ringkasan Temuan & Perbaikan

| # | Temuan dari Verifikasi                          | Status   |
|---|------------------------------------------------|----------|
| 1 | `as int? ?? 0` throw TypeError pada tipe salah | Diperbaiki → `is int` |
| 2 | `response.data as List` bisa crash              | Diperbaiki → `is! List` check |
| 3 | `.cast<>()` crash pada elemen null              | Diperbaiki → `.whereType<>()` |
| 4 | baseUrl tersebar di 2 tempat                    | Diperbaiki → terpusat di dioProvider |
| 5 | Timeout tersebar di 2 layer                     | Diperbaiki → hanya di BaseOptions |
| 6 | Doc comment warning `<Comment>`                 | Diperbaiki → backtick wrapping |
