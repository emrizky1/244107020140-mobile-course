import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/domain/repositories/note_repository.dart';
import 'package:campus_notify/features/notes/presentation/pages/notes_page.dart';
import 'package:campus_notify/features/notes/presentation/providers/notes_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeNoteRepository implements NoteRepository {
  final List<Note> notes = [];
  Failure? fetchFailure;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async =>
      (notes: List<Note>.unmodifiable(notes), failure: fetchFailure);

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
  testWidgets('empty note title shows validation feedback', (tester) async {
    final repository = FakeNoteRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [noteRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NotesPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add note'));
    await tester.pump();

    expect(find.text('Title cannot be empty.'), findsOneWidget);
    expect(repository.notes, isEmpty);
  });

  testWidgets('whitespace-only title shows validation feedback', (
    tester,
  ) async {
    final repository = FakeNoteRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [noteRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NotesPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '   \t  ');
    await tester.tap(find.text('Add note'));
    await tester.pump();

    expect(find.text('Title cannot be empty.'), findsOneWidget);
    expect(repository.notes, isEmpty);
  });

  testWidgets('valid title is trimmed and saved from the page', (tester) async {
    final repository = FakeNoteRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [noteRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NotesPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '  Weekly plan  ');
    await tester.enterText(find.byType(TextField).at(1), '  Review notes  ');
    await tester.tap(find.text('Add note'));
    await tester.pumpAndSettle();

    expect(repository.notes, hasLength(1));
    expect(repository.notes.single.title, 'Weekly plan');
    expect(repository.notes.single.body, 'Review notes');
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      isEmpty,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
      isEmpty,
    );
  });

  test('notifier rejects blank titles before calling the repository', () async {
    final repository = FakeNoteRepository();
    final container = ProviderContainer(
      overrides: [noteRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(notesProvider.notifier).add(title: '  \t ');

    expect(repository.notes, isEmpty);
    expect(container.read(notesProvider).failure, isA<ValidationFailure>());
    expect(
      container.read(notesProvider).failure?.message,
      'Title cannot be empty.',
    );
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
