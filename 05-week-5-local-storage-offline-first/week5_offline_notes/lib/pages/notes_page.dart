import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../data/sync.dart';
import '../widgets/note_tile.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesListProvider);
    final dirtyAsync = ref.watch(dirtyCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Notes'),
        actions: [
          // Dirty badge
          dirtyAsync.when(
            data: (count) => count > 0
                ? Badge(
                    label: Text('$count'),
                    child: IconButton(
                      icon: const Icon(Icons.sync),
                      tooltip: 'Sync dirty notes',
                      onPressed: () => _syncNotes(context, ref),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.cloud_done),
                    tooltip: 'All synced',
                    onPressed: null,
                  ),
            loading: () => const SizedBox.square(
              dimension: 48,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, _) => const Icon(Icons.error),
          ),
        ],
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notes) {
          if (notes.isEmpty) {
            return const Center(
              child: Text('No notes yet.\nTap + to add one.'),
            );
          }
          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return NoteTile(
                note: note,
                onTap: () {
                  if (note.id != null) {
                    context.push('/note/${note.id}');
                  }
                },
                onDelete: () async {
                  if (note.id != null) {
                    await ref
                        .read(noteRepositoryProvider)
                        .deleteNote(note.id!);
                    ref.invalidate(notesListProvider);
                    ref.invalidate(dirtyCountProvider);
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNote(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addNote(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(labelText: 'Body'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && titleController.text.isNotEmpty) {
      await ref.read(noteRepositoryProvider).addNote(
            title: titleController.text,
            body: bodyController.text,
          );
      ref.invalidate(notesListProvider);
      ref.invalidate(dirtyCountProvider);
    }
  }

  Future<void> _syncNotes(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final count = await syncNotes(ref.read(noteRepositoryProvider));
      ref.invalidate(notesListProvider);
      ref.invalidate(dirtyCountProvider);
      messenger.showSnackBar(
        SnackBar(content: Text('Synced $count note(s).')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Sync failed: $e')),
      );
    }
  }
}
