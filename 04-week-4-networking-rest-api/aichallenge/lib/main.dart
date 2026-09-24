import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/comment_provider.dart';

void main() {
  // ProviderScope WAJIB membungkus seluruh aplikasi agar
  // semua Riverpod provider bisa diakses oleh widget tree.
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JSONPlaceholder Comments',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const CommentPage(),
    );
  }
}

/// Halaman utama yang menampilkan daftar komentar dari API.
///
/// Menggunakan [ConsumerStatefulWidget] karena:
/// 1. Perlu `ref` untuk mengakses Riverpod provider.
/// 2. Perlu `initState` untuk memuat data saat pertama kali dibuka.
class CommentPage extends ConsumerStatefulWidget {
  const CommentPage({super.key});

  @override
  ConsumerState<CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends ConsumerState<CommentPage> {
  /// Post ID yang sedang ditampilkan komentarnya.
  int _currentPostId = 1;

  @override
  void initState() {
    super.initState();
    // Memuat komentar untuk post pertama saat halaman dibuka.
    // `Future.microtask` digunakan agar `ref` sudah tersedia.
    Future.microtask(
      () => ref.read(commentProvider.notifier).loadComments(_currentPostId),
    );
  }

  @override
  Widget build(BuildContext context) {
    // `ref.watch` mendengarkan perubahan state commentProvider.
    // Widget otomatis rebuild saat state berubah
    // (loading → data, data → error, dll).
    final commentState = ref.watch(commentProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Komentar Post #$_currentPostId'),
      ),
      body: Column(
        children: [
          // ============================================
          // SELECTOR: Pilih Post ID (1–10)
          // ============================================
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text(
                  'Pilih Post: ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 12),
                // Dropdown untuk memilih post ID.
                Expanded(
                  child: DropdownButton<int>(
                    value: _currentPostId,
                    isExpanded: true,
                    // Generate item 1–10 (JSONPlaceholder punya 100 post,
                    // tapi kita batasi 10 untuk demo).
                    items: List.generate(10, (i) => i + 1)
                        .map(
                          (id) => DropdownMenuItem(
                            value: id,
                            child: Text('Post #$id'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _currentPostId = value);
                        // Muat ulang komentar untuk post yang dipilih.
                        ref
                            .read(commentProvider.notifier)
                            .loadComments(value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ============================================
          // KONTEN: Loading / Error / Daftar Komentar
          // ============================================
          Expanded(
            // `commentState.when` otomatis menangani 3 state:
            // - loading: tampilkan spinner
            // - error: tampilkan pesan error ramah pengguna
            // - data: tampilkan list komentar
            child: commentState.when(
              // STATE: Loading — tampilkan indikator loading.
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),

              // STATE: Error — tampilkan pesan error + tombol retry.
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon error besar.
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      // Pesan error ramah pengguna dari getUserFriendlyError.
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      // Tombol retry untuk mencoba lagi.
                      FilledButton.icon(
                        onPressed: () => ref
                            .read(commentProvider.notifier)
                            .loadComments(_currentPostId),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              ),

              // STATE: Data berhasil dimuat — tampilkan list komentar.
              data: (comments) {
                // Jika list kosong, tampilkan pesan "tidak ada komentar".
                if (comments.isEmpty) {
                  return const Center(
                    child: Text(
                      'Tidak ada komentar untuk post ini.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                // Tampilkan komentar dalam ListView.
                return ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: comments.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return ListTile(
                      // Avatar dengan inisial dari nama pengirim.
                      leading: CircleAvatar(
                        child: Text(
                          comment.name.isNotEmpty
                              ? comment.name[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      // Nama pengirim komentar.
                      title: Text(
                        comment.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Email pengirim sebagai subtitle.
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.email,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Isi komentar.
                          Text(comment.body),
                        ],
                      ),
                      isThreeLine: true,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // FAB untuk refresh manual.
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref
            .read(commentProvider.notifier)
            .loadComments(_currentPostId),
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
