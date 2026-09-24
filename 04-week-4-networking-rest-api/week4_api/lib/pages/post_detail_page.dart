import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/providers.dart';

/// Halaman detail post yang menampilkan judul dan isi post lengkap,
/// serta daftar komentar terkait.
///
/// Diakses via GoRouter dengan rute `/post/:id`.
///
/// Sesuai requirement:
/// - State detail post diambil secara cerdas lewat [postDetailProvider]:
///   1. Dari list yang sudah dimuat ([postListProvider]) jika ada.
///   2. Via [PostRepository.fetchPost] bila langsung dibuka melalui URL/deep-link.
/// - Menampilkan title dan body lengkap.
/// - Menampilkan komentar post terkait via [commentListProvider].
class PostDetailPage extends ConsumerWidget {
  const PostDetailPage({super.key, required this.postId});

  /// ID dari post yang akan ditampilkan.
  final int postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ambil data post: dari cache list jika ada, atau fetch API jika langsung dibuka.
    final postAsync = ref.watch(postDetailProvider(postId));
    // Ambil data komentar via repository.
    final commentsAsync = ref.watch(commentListProvider(postId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Post #$postId'),
        actions: [
          // Tombol refresh untuk memuat ulang detail post dan komentar.
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(postDetailProvider(postId));
              ref.read(commentListProvider(postId).notifier).refresh();
            },
          ),
        ],
      ),
      body: postAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  friendlyErrorMessage(err),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(postDetailProvider(postId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (post) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === Judul Lengkap Post ===
              Text(
                post.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),

              // Chip info user dan ID
              Chip(
                avatar: const Icon(Icons.person, size: 18),
                label: Text('User ${post.userId} • Post #${post.id}'),
              ),
              const SizedBox(height: 16),

              // === Body Lengkap Post ===
              Text(
                post.body,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                    ),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),

              // === Bagian Komentar ===
              Text(
                'Komentar',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),

              commentsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          friendlyErrorMessage(err),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () =>
                              ref.invalidate(commentListProvider(postId)),
                          child: const Text('Coba lagi muat komentar'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (comments) {
                  if (comments.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Belum ada komentar.'),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: comments.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comment.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.email_outlined,
                                    size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    comment.email,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(comment.body),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
