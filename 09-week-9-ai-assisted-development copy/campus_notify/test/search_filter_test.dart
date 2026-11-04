import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/domain/repositories/note_repository.dart';
import 'package:campus_notify/features/notes/domain/usecases/filter_notes.dart';
import 'package:campus_notify/features/notes/presentation/pages/notes_page.dart';
import 'package:campus_notify/features/notes/presentation/providers/notes_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SearchNoteRepository implements NoteRepository {
  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async => (
    notes: [
      Note(
        id: 1,
        title: 'Weekly groceries',
        updatedAt: DateTime.utc(2026, 10, 15),
      ),
    ],
    failure: null,
  );

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async => (
    note: Note(title: title, body: body, updatedAt: DateTime.utc(2026)),
    failure: null,
  );
}

void main() {
  final notes = [
    Note(title: 'Groceries', body: 'Milk', updatedAt: DateTime.utc(2026)),
    Note(title: 'GROCERIES list', updatedAt: DateTime.utc(2026)),
    Note(
      title: 'Lecture notes',
      body: 'groceries',
      updatedAt: DateTime.utc(2026),
    ),
  ];

  test('title search ignores case and matches multiple titles', () {
    expect(filterNotesByTitle(notes, ' groceries '), hasLength(2));
  });

  test('title search returns no notes when the title does not match', () {
    expect(filterNotesByTitle(notes, 'zzz-missing'), isEmpty);
  });

  test('empty title query returns every note', () {
    expect(filterNotesByTitle(notes, '  '), hasLength(3));
  });

  testWidgets('no-match search shows empty state and clearing restores notes', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          noteRepositoryProvider.overrideWithValue(_SearchNoteRepository()),
        ],
        child: const MaterialApp(home: NotesPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Weekly groceries'), findsOneWidget);
    final searchField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Search note titles',
    );
    await tester.enterText(searchField, 'zzz-missing');
    await tester.pump();

    expect(find.text('Tidak ada judul catatan yang cocok.'), findsOneWidget);
    expect(find.text('Weekly groceries'), findsNothing);

    await tester.enterText(searchField, '');
    await tester.pump();
    expect(find.text('Weekly groceries'), findsOneWidget);
  });
}
