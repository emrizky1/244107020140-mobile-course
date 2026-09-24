# AI Challenge Documentation — Week 4 REST API & Networking

## 1. Task Overview
Build a Flutter repository layer for endpoint `GET /comments?postId={id}` from JSONPlaceholder using Dio + flutter_riverpod with:
- Null-safe `Comment` model (`postId`, `id`, `name`, `email`, `body`).
- `CommentRepository` with a centralized 10-second timeout.
- `AsyncNotifierProvider` with automated error handling and user-friendly error messages.
- Comprehensive unit testing covering missing fields and edge cases.
- Refactoring `PostTile` widget, centralized `network_errors.dart`, and GoRouter `/post/:id` navigation.

---

## 2. Prompts Used

### Prompt 1: Repository Layer & Comment Model Implementation
```
Buatkan repository layer Flutter untuk endpoint GET /comments?postId={id}
dari JSONPlaceholder menggunakan Dio + flutter_riverpod.
Requirements:
- Model Comment dengan fromJson aman null (postId, id, name, email, body).
- CommentRepository dengan method fetchComments(postId) + timeout 10 detik.
- AsyncNotifierProvider dengan penanganan error otomatis (AsyncError)
  dan fungsi pesan error ramah pengguna untuk timeout, connection error, 404, dan 500.
- Satu unit test untuk fromJson dengan field yang hilang.
Jelaskan setiap bagian kode dalam komentar.

AI Verification Checklist:
1. Apakah UI memanggil Dio secara langsung (dilarang) atau lewat repository?
2. Apakah fromJson aman null, atau masih memakai cast langsung yang bisa crash?
3. Apakah semua tipe DioExceptionType (timeout, connectionError, badResponse) dipetakan ke pesan pengguna?
4. Apakah baseUrl/timeout terpusat di satu client, bukan tersebar di tiap method?
5. Apakah test AI benar-benar menguji kasus field hilang, atau hanya happy path? Tambahkan minimal 1 edge case sendiri.
6. Jalankan flutter analyze dan flutter test, apakah hasil AI lolos tanpa warning?
```

### Prompt 2: Refactoring Challenge
```
Refactoring Challenge:
1. Ekstrak widget baris post menjadi PostTile tersendiri agar ListView.builder pendek dan mudah diuji.
2. Pindahkan friendlyErrorMessage ke file lib/data/network_errors.dart agar bisa dipakai ulang halaman paged dan non-paged.
3. Tambahkan halaman detail post dengan GoRouter (/post/:id) yang menampilkan title dan body lengkap, state detail diambil dari list yang sudah dimuat atau via repository bila langsung dibuka.
```

### Prompt 3: Hermetic Unit Testing
```
Testing: unit test model + mock repository
Buat test/post_test.dart, uji parsing aman null, mapping error, dan provider dengan repository palsu (tanpa internet).
```

---

## 3. Discovered AI Code Issues & Applied Solutions

1. **Riverpod 3 Notifier Class Hierarchy**:
   - *Issue*: AI initially attempted to inherit from `FamilyAsyncNotifier<List<Comment>, int>`, which does not exist in modern Riverpod 3.x.
   - *Impact*: Compilation failed with `extends_non_class` error.
   - *Correction*: Adopted the official Riverpod 3 pattern: `AsyncNotifierProvider.family<CommentListNotifier, List<Comment>, int>` with a notifier class extending standard `AsyncNotifier<List<Comment>>` and receiving `postId` via constructor dependency injection.

2. **Model Number Parsing**:
   - *Issue*: Parsing integer fields with `as int? ?? 0` fails when JSON decoders return `double` (e.g. `1.0`).
   - *Impact*: Throws runtime `TypeError: 1.0 is not a subtype of type int`.
   - *Correction*: Changed to `(json['postId'] as num?)?.toInt() ?? 0`, which safely handles integer, double, and null values.

3. **Pending Timers in Widget Tests**:
   - *Issue*: Widget tests on `MyApp` triggered default `dioProvider` initialization, leaving active 10-second timeout timers.
   - *Impact*: Widget tests failed with `A Timer is still pending even after the widget tree was disposed`.
   - *Correction*: Overrode `postRepositoryProvider` with `FakePostRepository` in widget test `ProviderScope`, enabling instant, hermetic execution.

4. **Post Detail State Optimization**:
   - *Issue*: Navigating to `/post/:id` triggered duplicate network requests even when the post was already present in the list state.
   - *Correction*: Used `ref.read(postListProvider)` in `postDetailProvider`. If the post is already loaded, it is returned synchronously from memory. An API fetch is only performed when opened directly via a deep link or URL.

---

## 4. Technical Rationale

1. **Centralized `network_errors.dart`**:
   Eliminates duplicated error translation logic across UI screens, providing consistent user-friendly error messages in one place.
2. **Extracted `PostTile`**:
   Isolates post row presentation, making list views clean and allowing independent widget testing.
3. **Decoupled `api_client.dart`**:
   Ensures `baseUrl`, timeouts, and logging interceptors are configured once, making environment configuration straightforward.
