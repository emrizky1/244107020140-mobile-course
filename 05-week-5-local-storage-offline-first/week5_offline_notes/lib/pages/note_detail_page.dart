import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/note.dart';
import '../providers/providers.dart';

/// Provider that fetches a single note by ID from the local repository.
final noteDetailProvider = FutureProvider.family<Note?, int>((ref, id) async {
  final repo = ref.watch(noteRepositoryProvider);
  final notes = await repo.fetchNotes();
  try {
    return notes.firstWhere((n) => n.id == id);
  } catch (_) {
    return null;
  }
});

/// Detail page for a single note, accessed via GoRouter at /note/:id.
/// Reads directly from the local repository, not from list page state.
class NoteDetailPage extends ConsumerWidget {
  const NoteDetailPage({super.key, required this.noteId});

  final int noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(noteDetailProvider(noteId));

    return Scaffold(
      appBar: AppBar(title: const Text('Note Detail')),
      body: noteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (note) {
          if (note == null) {
            return const Center(child: Text('Note not found.'));
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sync status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: note.dirty
                        ? Colors.orange.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    note.dirty ? 'Unsynced' : 'Synced',
                    style: TextStyle(
                      color: note.dirty
                          ? Colors.orange.shade900
                          : Colors.green.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Title
                Text(
                  note.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                // Updated at
                Text(
                  'Last updated: ${note.updatedAt.toLocal()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                // Body
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      note.body.isEmpty ? '(no body)' : note.body,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
