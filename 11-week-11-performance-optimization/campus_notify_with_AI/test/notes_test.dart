import 'dart:async';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/domain/repositories/note_repository.dart';
import 'package:campus_notify/features/notes/presentation/providers/notes_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeNoteRepository implements NoteRepository {
  final List<Note> notes = [];
  Failure? fetchFailure;
  Completer<({List<Note> notes, Failure? failure})>? fetchCompleter;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() =>
      fetchCompleter?.future ??
      Future.value((
        notes: List<Note>.unmodifiable(notes),
        failure: fetchFailure,
      ));

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    final note = Note(
      id: notes.length + 1,
      title: title,
      body: body,
      updatedAt: DateTime.utc(2026, 10, 15),
      dirty: true,
    );
    notes.insert(0, note);
    return (note: note, failure: null);
  }
}

void main() {
  test('notifier sends search queries through the domain use case', () async {
    final repository = FakeNoteRepository()
      ..notes.addAll([
        Note(title: 'Groceries', updatedAt: DateTime.utc(2026)),
        Note(title: 'Lecture notes', updatedAt: DateTime.utc(2026)),
      ]);
    final container = ProviderContainer(
      overrides: [noteRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final notifier = container.read(notesProvider.notifier);
    await notifier.load();
    notifier.search('lecture');

    final state = container.read(notesProvider);
    expect(state.searchQuery, 'lecture');
    expect(state.visibleNotes.map((note) => note.title), ['Lecture notes']);
  });

  test('load completion does not discard a note added while loading', () async {
    final repository = FakeNoteRepository()..fetchCompleter = Completer();
    final container = ProviderContainer(
      overrides: [noteRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final load = container.read(notesProvider.notifier).load();
    await container.read(notesProvider.notifier).add(title: 'New note');
    repository.fetchCompleter!.complete((notes: <Note>[], failure: null));
    await load;

    expect(container.read(notesProvider).notes.map((note) => note.title), [
      'New note',
    ]);
  });

  test(
    'notes state loads and adds notes through the repository contract',
    () async {
      final repository = FakeNoteRepository();
      final container = ProviderContainer(
        overrides: [noteRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container.read(notesProvider.notifier).load();
      expect(container.read(notesProvider).notes, isEmpty);

      await container
          .read(notesProvider.notifier)
          .add(title: 'Lab 3', body: 'Riverpod wiring');

      final state = container.read(notesProvider);
      expect(state.notes, hasLength(1));
      expect(state.notes.single.title, 'Lab 3');
      expect(state.notes.single.body, 'Riverpod wiring');
      expect(state.failure, isNull);
    },
  );

  test('notes state keeps repository failures explicit', () async {
    final repository = FakeNoteRepository()
      ..fetchFailure = const LocalFailure('database unavailable');
    final container = ProviderContainer(
      overrides: [noteRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(notesProvider.notifier).load();

    expect(
      container.read(notesProvider).failure?.message,
      'database unavailable',
    );
  });
}
