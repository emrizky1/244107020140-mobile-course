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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildEditor(),
                const SizedBox(height: 20),
                _buildSearchField(),
                const SizedBox(height: 12),
              ]),
            ),
          ),
          _buildNotes(),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return Consumer(
      builder: (context, ref, child) {
        final isSaving = ref.watch(
          notesProvider.select((state) => state.isSaving),
        );

        final failure = ref.watch(
          notesProvider.select((state) => state.failure),
        );

        return Column(
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
              onPressed: isSaving
                  ? null
                  : () async {
                      final title = _title.text.trim();
                      if (title.isEmpty) return;

                      await ref
                          .read(notesProvider.notifier)
                          .add(title: title, body: _body.text.trim());

                      if (ref.read(notesProvider).failure == null) {
                        _title.clear();
                        _body.clear();
                      }
                    },
              icon: isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: const Text('Add note'),
            ),
            if (failure != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      failure.message,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => ref.read(notesProvider.notifier).load(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSearchField() => TextField(
    controller: _search,
    onChanged: (value) => ref.read(notesProvider.notifier).search(value),
    decoration: const InputDecoration(
      labelText: 'Search note titles',
      prefixIcon: Icon(Icons.search),
      border: OutlineInputBorder(),
    ),
  );

  Widget _buildNotes() {
    return Consumer(
      builder: (context, ref, child) {
        final notesView = ref.watch(
          notesProvider.select(
            (state) => (
              state.visibleNotes,
              state.isLoading,
              state.failure,
              state.searchQuery,
            ),
          ),
        );

        final notes = notesView.$1;
        final isLoading = notesView.$2;
        final failure = notesView.$3;
        final searchQuery = notesView.$4;

        if (isLoading) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (notes.isEmpty && failure == null) {
          return SliverFillRemaining(
            child: Center(
              child: Text(
                searchQuery.trim().isNotEmpty
                    ? 'Tidak ada judul catatan yang cocok.'
                    : 'Belum ada catatan.',
              ),
            ),
          );
        }

        if (notes.isEmpty && failure != null) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];

              return NoteCard(
                title: note.title,
                body: note.body,
                updatedAt: note.updatedAt,
                dirty: note.dirty,
              );
            },
          ),
        );
      },
    );
  }
}

class NoteCard extends StatelessWidget {
  final String title;
  final String body;
  final DateTime updatedAt;
  final bool dirty;

  const NoteCard({
    super.key,
    required this.title,
    required this.body,
    required this.updatedAt,
    required this.dirty,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(
          body.isEmpty ? ' ' : body,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(formatDateTime(updatedAt)),
            if (dirty) const Text('Local'),
          ],
        ),
      ),
    );
  }
}
