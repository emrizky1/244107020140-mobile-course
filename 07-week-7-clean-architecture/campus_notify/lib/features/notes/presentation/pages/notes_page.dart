import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format.dart';
import '../../domain/validation/note_title_validator.dart';
import '../providers/notes_providers.dart';

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  final _title = TextEditingController();
  final _body = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(notesProvider.notifier).load());
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _addNote() async {
    final title = _title.text.trim();
    final validationFailure = validateNoteTitle(title);
    if (validationFailure != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(validationFailure.message)));
      return;
    }
    await ref
        .read(notesProvider.notifier)
        .add(title: title, body: _body.text.trim());
    final state = ref.read(notesProvider);
    if (state.failure == null) {
      _title.clear();
      _body.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _body,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Body',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: state.isSaving ? null : _addNote,
            icon: state.isSaving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
            label: const Text('Add note'),
          ),
          if (state.failure != null) ...[
            const SizedBox(height: 12),
            Text(
              state.failure!.message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            TextButton.icon(
              onPressed: state.isLoading
                  ? null
                  : () => ref.read(notesProvider.notifier).load(),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
          const SizedBox(height: 20),
          if (state.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (state.notes.isEmpty && state.failure == null)
            const Center(child: Text('Belum ada catatan.'))
          else
            ...state.notes.map(
              (note) => Card(
                child: ListTile(
                  title: Text(note.title),
                  subtitle: Text(
                    note.body.isEmpty ? ' ' : note.body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatDateTime(note.updatedAt)),
                      if (note.dirty) const Text('Local'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
