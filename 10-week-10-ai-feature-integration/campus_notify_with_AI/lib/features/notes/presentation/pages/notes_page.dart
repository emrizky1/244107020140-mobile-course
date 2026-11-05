import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format.dart';
import '../providers/notes_providers.dart';

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(notesProvider.notifier).load());
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _addNote() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;
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
          _buildEditor(context, state),
          const SizedBox(height: 20),
          _buildSearchField(),
          const SizedBox(height: 12),
          _buildNotes(state),
        ],
      ),
    );
  }

  Widget _buildEditor(BuildContext context, NotesState state) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
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
      if (state.failure != null) _buildFailure(context, state),
    ],
  );

  Widget _buildFailure(BuildContext context, NotesState state) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    ),
  );

  Widget _buildSearchField() => TextField(
    controller: _search,
    onChanged: (value) => ref.read(notesProvider.notifier).search(value),
    decoration: const InputDecoration(
      labelText: 'Search note titles',
      prefixIcon: Icon(Icons.search),
      border: OutlineInputBorder(),
    ),
  );

  Widget _buildNotes(NotesState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.notes.isEmpty && state.failure == null) {
      return const Center(child: Text('Belum ada catatan.'));
    }
    if (state.visibleNotes.isEmpty && state.failure == null) {
      return const Center(child: Text('Tidak ada judul catatan yang cocok.'));
    }
    return Column(
      children: state.visibleNotes.map<Widget>((note) {
        return Card(
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
        );
      }).toList(),
    );
  }
}
