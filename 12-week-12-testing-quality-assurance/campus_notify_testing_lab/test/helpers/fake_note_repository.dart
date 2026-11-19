import 'dart:async';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/domain/repositories/note_repository.dart';

/// In-memory [NoteRepository] whose behaviour each test controls.
///
/// * Set [fetchFailure] / [addFailure] to simulate errors.
/// * Set [fetchGate] / [addGate] to hold a call open until the test completes
///   the gate, which makes "loading" and "saving" states observable.
/// * Set [staleFetchResult] to make a slow fetch return an old snapshot,
///   ignoring notes added while it was waiting.
/// * [fetchCalls] / [addCalls] record how often the app reached the data layer.
class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository({List<Note> initialNotes = const []})
    : notes = [...initialNotes];

  final List<Note> notes;

  Failure? fetchFailure;
  Failure? addFailure;
  Completer<void>? fetchGate;
  Completer<void>? addGate;
  List<Note>? staleFetchResult;

  int fetchCalls = 0;
  int addCalls = 0;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    fetchCalls++;
    await fetchGate?.future;
    return (
      notes: List<Note>.unmodifiable(staleFetchResult ?? notes),
      failure: fetchFailure,
    );
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    addCalls++;
    await addGate?.future;

    final failure = addFailure;
    if (failure != null) return (note: null, failure: failure);

    final note = Note(
      id: notes.length + 1,
      title: title,
      body: body,
      updatedAt: DateTime(2026, 11, 19, 8, 30),
      dirty: true,
    );
    notes.insert(0, note);
    return (note: note, failure: null);
  }
}
