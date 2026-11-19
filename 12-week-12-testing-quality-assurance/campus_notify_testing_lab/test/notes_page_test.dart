import 'dart:async';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/presentation/pages/notes_page.dart';
import 'package:campus_notify/features/notes/presentation/providers/notes_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_note_repository.dart';

const _titleField = Key('note-title-field');
const _bodyField = Key('note-body-field');
const _addButton = Key('add-note-button');

Future<void> _pumpNotesPage(
  WidgetTester tester,
  FakeNoteRepository repository,
) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [noteRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: NotesPage()),
    ),
  );
}

String _fieldText(WidgetTester tester, Key key) =>
    tester.widget<TextField>(find.byKey(key)).controller!.text;

void main() {
  group('initial display', () {
    testWidgets('shows the editor and the empty state when there are no notes', (
      tester,
    ) async {
      await _pumpNotesPage(tester, FakeNoteRepository());
      await tester.pumpAndSettle();

      expect(find.byKey(_titleField), findsOneWidget);
      expect(find.byKey(_bodyField), findsOneWidget);
      expect(find.byKey(_addButton), findsOneWidget);
      expect(find.text('Belum ada catatan.'), findsOneWidget);
    });

    testWidgets('lists saved notes and marks only unsynced ones as Local', (
      tester,
    ) async {
      final repository = FakeNoteRepository(
        initialNotes: [
          Note(
            id: 2,
            title: 'Read the material',
            body: 'Chapter 12',
            updatedAt: DateTime(2026, 11, 19, 8, 30),
            dirty: true,
          ),
          Note(
            id: 1,
            title: 'Submit the lab',
            updatedAt: DateTime(2026, 11, 18, 21, 5),
          ),
        ],
      );

      await _pumpNotesPage(tester, repository);
      await tester.pumpAndSettle();

      expect(find.text('Read the material'), findsOneWidget);
      expect(find.text('Submit the lab'), findsOneWidget);
      expect(find.text('19/11/2026 08:30'), findsOneWidget);
      expect(find.text('Local'), findsOneWidget);
      expect(find.text('Belum ada catatan.'), findsNothing);
    });

    testWidgets('shows a loading indicator until the notes arrive', (
      tester,
    ) async {
      final repository = FakeNoteRepository()..fetchGate = Completer<void>();

      await _pumpNotesPage(tester, repository);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      repository.fetchGate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Belum ada catatan.'), findsOneWidget);
    });
  });

  group('invalid input', () {
    testWidgets('a whitespace-only title is ignored and never saved', (
      tester,
    ) async {
      final repository = FakeNoteRepository();
      await _pumpNotesPage(tester, repository);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(_titleField), '   ');
      await tester.tap(find.byKey(_addButton));
      await tester.pumpAndSettle();

      expect(repository.addCalls, 0);
      expect(find.text('Belum ada catatan.'), findsOneWidget);
    });
  });

  group('adding a note', () {
    testWidgets('a valid note appears in the list and the form is cleared', (
      tester,
    ) async {
      final repository = FakeNoteRepository();
      await _pumpNotesPage(tester, repository);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(_titleField), 'Read the material');
      await tester.enterText(find.byKey(_bodyField), 'Chapter 12');
      await tester.tap(find.byKey(_addButton));
      await tester.pumpAndSettle();

      expect(repository.addCalls, 1);
      expect(find.text('Read the material'), findsOneWidget);
      expect(find.text('Chapter 12'), findsOneWidget);
      expect(find.text('Local'), findsOneWidget);
      expect(find.text('Belum ada catatan.'), findsNothing);
      expect(_fieldText(tester, _titleField), isEmpty);
      expect(_fieldText(tester, _bodyField), isEmpty);
    });

    testWidgets('a save failure shows the error and keeps what was typed', (
      tester,
    ) async {
      final repository = FakeNoteRepository()
        ..addFailure = const LocalFailure('Catatan gagal disimpan.');
      await _pumpNotesPage(tester, repository);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(_titleField), 'Read the material');
      await tester.tap(find.byKey(_addButton));
      await tester.pumpAndSettle();

      expect(find.text('Catatan gagal disimpan.'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(_fieldText(tester, _titleField), 'Read the material');
      expect(repository.notes, isEmpty);
    });

    testWidgets('the button is disabled while a save is in progress', (
      tester,
    ) async {
      final repository = FakeNoteRepository()..addGate = Completer<void>();
      await _pumpNotesPage(tester, repository);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(_titleField), 'Slow save');
      await tester.tap(find.byKey(_addButton));
      await tester.pump();

      expect(
        tester.widget<FilledButton>(find.byKey(_addButton)).onPressed,
        isNull,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      repository.addGate!.complete();
      await tester.pumpAndSettle();

      expect(
        tester.widget<FilledButton>(find.byKey(_addButton)).onPressed,
        isNotNull,
      );
      expect(find.text('Slow save'), findsOneWidget);
    });
  });
}
