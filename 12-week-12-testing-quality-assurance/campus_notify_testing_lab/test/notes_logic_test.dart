import 'package:campus_notify/features/notes/data/models/note_model.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/domain/usecases/filter_notes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('filterNotesByTitle', () {
    final notes = [
      Note(title: 'Weekly groceries', updatedAt: DateTime.utc(2026, 11, 1)),
      Note(
        title: 'Lecture notes',
        body: 'groceries are not a lecture topic',
        updatedAt: DateTime.utc(2026, 11, 2),
      ),
      Note(title: 'GROCERIES for lab', updatedAt: DateTime.utc(2026, 11, 3)),
    ];

    test('matches titles ignoring case and surrounding whitespace', () {
      final result = filterNotesByTitle(notes, '  Groceries ');

      expect(result.map((note) => note.title), [
        'Weekly groceries',
        'GROCERIES for lab',
      ]);
    });

    test('searches titles only, never the body text', () {
      final result = filterNotesByTitle(notes, 'topic');

      expect(result, isEmpty);
    });

    test('keeps the original order of the matching notes', () {
      final result = filterNotesByTitle(notes, 'o');

      expect(result.map((note) => note.title), [
        'Weekly groceries',
        'Lecture notes',
        'GROCERIES for lab',
      ]);
    });

    test('returns every note for an empty or whitespace-only query', () {
      expect(filterNotesByTitle(notes, ''), notes);
      expect(filterNotesByTitle(notes, '   '), notes);
    });

    test('returns an empty list when there is nothing to search', () {
      expect(filterNotesByTitle(const [], 'anything'), isEmpty);
    });

    test('FilterNotes use case delegates to the same rule', () {
      const useCase = FilterNotes();

      expect(
        useCase(notes, 'lecture').map((note) => note.title),
        ['Lecture notes'],
      );
    });
  });

  group('NoteModel mapping', () {
    final updatedAt = DateTime.utc(2026, 11, 19, 8, 30);

    test('round-trips through toMap and fromMap', () {
      final original = NoteModel(
        id: 7,
        title: 'Read the material',
        body: 'Chapter 12',
        updatedAt: updatedAt,
        dirty: true,
      );

      final restored = NoteModel.fromMap(original.toMap());

      expect(restored.id, 7);
      expect(restored.title, 'Read the material');
      expect(restored.body, 'Chapter 12');
      expect(restored.updatedAt, updatedAt);
      expect(restored.dirty, isTrue);
    });

    test('stores the dirty flag as 1 or 0 for SQLite', () {
      final dirty = NoteModel(title: 'a', updatedAt: updatedAt, dirty: true);
      final clean = NoteModel(title: 'a', updatedAt: updatedAt);

      expect(dirty.toMap()['dirty'], 1);
      expect(clean.toMap()['dirty'], 0);
    });

    test('falls back to safe defaults when columns are null or missing', () {
      final model = NoteModel.fromMap(const {'id': null});

      expect(model.id, isNull);
      expect(model.title, '');
      expect(model.body, '');
      expect(model.dirty, isFalse);
      expect(model.updatedAt, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('falls back to the epoch when the stored date is corrupt', () {
      final model = NoteModel.fromMap(const {
        'title': 'Broken date',
        'updated_at': 'not-a-date',
      });

      expect(model.title, 'Broken date');
      expect(model.updatedAt, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('toEntity keeps every field', () {
      final entity = NoteModel(
        id: 3,
        title: 'Title',
        body: 'Body',
        updatedAt: updatedAt,
        dirty: true,
      ).toEntity();

      expect(entity.id, 3);
      expect(entity.title, 'Title');
      expect(entity.body, 'Body');
      expect(entity.updatedAt, updatedAt);
      expect(entity.dirty, isTrue);
    });
  });
}
