import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../local/db.dart';
import '../models/post.dart';

/// Handles reading/writing cached posts to the local SQLite `cached_posts` table.
class CachedPostRepository {
  CachedPostRepository({Future<Database> Function()? openDb})
      : _openDb = openDb ?? openNotesDb;

  final Future<Database> Function() _openDb;

  /// Reads all cached posts from the local database.
  Future<List<Post>> readCachedPosts() async {
    final db = await _openDb();
    final rows = await db.query('cached_posts', orderBy: 'id ASC');
    return rows.map((row) {
      final payload = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
      return Post.fromJson(payload);
    }).toList();
  }

  /// Saves a list of posts to the local cache, replacing any existing data.
  Future<void> saveCachedPosts(List<Post> posts) async {
    final db = await _openDb();
    final batch = db.batch();
    batch.delete('cached_posts');
    final now = DateTime.now().toIso8601String();
    for (final post in posts) {
      batch.insert('cached_posts', {
        'id': post.id,
        'payload': jsonEncode(post.toJson()),
        'cached_at': now,
      });
    }
    await batch.commit(noResult: true);
  }
}
