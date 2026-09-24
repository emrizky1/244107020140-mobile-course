import 'package:flutter/material.dart';
import '../data/models/post.dart';

/// Widget baris untuk menampilkan item [Post] dalam daftar.
///
/// Diekstrak dari `ListView.builder` agar tampilan lebih modular,
/// rapi, reusable (bisa dipakai di paged maupun non-paged list),
/// dan mudah diuji secara terisolasi dengan widget test.
class PostTile extends StatelessWidget {
  const PostTile({
    super.key,
    required this.post,
    this.onTap,
  });

  /// Data post yang akan ditampilkan.
  final Post post;

  /// Callback ketika item ditekan (misal navigasi ke detail post).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(post.id.toString()),
      ),
      title: Text(
        post.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        post.body,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
