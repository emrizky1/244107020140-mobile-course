import 'dart:async';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/data/repositories/note_repository_impl.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/presentation/providers/notes_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_note_repository.dart';

ProviderContainer _containerWith(FakeNoteRepository repository) {
  final container = ProviderContainer(
    overrides: [noteRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('NotesNotifier.add with a fake repository', () {
    test('success puts the new note first and clears the saving flag', () async {
      final repository = FakeNoteRepository(
        initialNotes: [
          Note(id: 1, title: 'Old note', updatedAt: DateTime.utc(2026, 11, 1)),
        ],
      );
      final container = _containerWith(repository);
      final notifier = container.read(notesProvider.notifier);

      await notifier.load();
      await notifier.add(title: 'Read the material', body: 'Chapter 12');

      final state = container.read(notesProvider);
      expect(state.notes.map((note) => note.title), [
        'Read the material',
        'Old note',
      ]);
      expect(state.isSaving, isFalse);
      expect(state.failure, isNull);
    });

    test('failure keeps the list unchanged and exposes the error', () async {
      final repository = FakeNoteRepository()
        ..addFailure = const LocalFailure('Catatan gagal disimpan.');
      final container = _containerWith(repository);
      final notifier = container.read(notesProvider.notifier);

      await notifier.load();
      await notifier.add(title: 'Will not be saved');

      final state = container.read(notesProvider);
      expect(state.notes, isEmpty);
      expect(state.isSaving, isFalse);
      expect(state.failure, isA<LocalFailure>());
      expect(state.failure?.message, 'Catatan gagal disimpan.');
    });

    test('isSaving stays true until the repository answers', () async {
      final repository = FakeNoteRepository()..addGate = Completer<void>();
      final container = _containerWith(repository);
      final notifier = container.read(notesProvider.notifier);

      final saving = notifier.add(title: 'Slow save');
      expect(container.read(notesProvider).isSaving, isTrue);

      repository.addGate!.complete();
      await saving;

      expect(container.read(notesProvider).isSaving, isFalse);
    });

    test('a note that does not match the active search is hidden', () async {
      final repository = FakeNoteRepository(
        initialNotes: [
          Note(
            id: 1,
            title: 'Lecture notes',
            updatedAt: DateTime.utc(2026, 11, 1),
          ),
        ],
      );
      final container = _containerWith(repository);
      final notifier = container.read(notesProvider.notifier);

      await notifier.load();
      notifier.search('lecture');
      await notifier.add(title: 'Groceries');

      final state = container.read(notesProvider);
      expect(state.notes.map((note) => note.title), [
        'Groceries',
        'Lecture notes',
      ]);
      expect(state.visibleNotes.map((note) => note.title), ['Lecture notes']);
    });
  });

  group('NotesNotifier.load with a fake repository', () {
    test('a later successful load clears an earlier failure', () async {
      final repository = FakeNoteRepository()
        ..fetchFailure = const LocalFailure('Catatan gagal dimuat.');
      final container = _containerWith(repository);
      final notifier = container.read(notesProvider.notifier);

      await notifier.load();
      expect(container.read(notesProvider).failure, isNotNull);

      repository.fetchFailure = null;
      await notifier.load();

      expect(container.read(notesProvider).failure, isNull);
      expect(repository.fetchCalls, 2);
    });
  });

  group('NoteRepositoryImpl when the database cannot be opened', () {
    final repository = NoteRepositoryImpl(
      openDb: () async => throw StateError('database unavailable'),
    );

    test('fetchNotes returns an empty list and a LocalFailure', () async {
      final result = await repository.fetchNotes();

      expect(result.notes, isEmpty);
      expect(result.failure, isA<LocalFailure>());
      expect(result.failure?.message, 'Catatan gagal dimuat.');
    });

    test('addNote returns no note and a LocalFailure', () async {
      final result = await repository.addNote(title: 'Anything');

      expect(result.note, isNull);
      expect(result.failure, isA<LocalFailure>());
      expect(result.failure?.message, 'Catatan gagal disimpan.');
    });
  });
}
