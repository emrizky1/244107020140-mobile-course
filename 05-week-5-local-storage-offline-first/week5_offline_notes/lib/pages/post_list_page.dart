import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/post.dart';
import '../providers/providers.dart';

class PostListPage extends ConsumerWidget {
  const PostListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsProvider);
    final isOffline = ref.watch(forceOfflineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cached Posts'),
        actions: [
          Row(
            children: [
              Icon(
                isOffline ? Icons.airplanemode_active : Icons.wifi,
                size: 20,
              ),
              Switch(
                value: isOffline,
                onChanged: (v) =>
                    ref.read(forceOfflineProvider.notifier).toggle(v),
              ),
            ],
          ),
        ],
      ),
      body: postsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(
              child: Text('No cached posts yet.\nPull down to refresh.'),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(postsProvider.notifier).refresh(),
            child: ListView.separated(
              itemCount: posts.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final post = posts[index];
                return _PostTile(post: post);
              },
            ),
          );
        },
      ),
    );
  }
}

class _PostTile extends StatelessWidget {
  const _PostTile({required this.post});
  final Post post;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text('${post.id}')),
      title: Text(post.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(post.body, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}
