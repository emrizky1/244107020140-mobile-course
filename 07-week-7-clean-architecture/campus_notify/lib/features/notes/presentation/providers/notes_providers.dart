import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/failures.dart';
import '../../data/notes_database.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/validation/note_title_validator.dart';

final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepositoryImpl(openDb: openNotesDatabase),
);

class NotesState {
  const NotesState({
    this.notes = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.failure,
  });

  final List<Note> notes;
  final bool isLoading;
  final bool isSaving;
  final Failure? failure;
}

final notesProvider = NotifierProvider<NotesNotifier, NotesState>(
  NotesNotifier.new,
);

class NotesNotifier extends Notifier<NotesState> {
  @override
  NotesState build() => const NotesState();

  Future<void> load() async {
    state = NotesState(notes: state.notes, isLoading: true);
    final result = await ref.read(noteRepositoryProvider).fetchNotes();
    state = NotesState(notes: result.notes, failure: result.failure);
  }

  Future<void> add({required String title, String body = ''}) async {
    final validationFailure = validateNoteTitle(title);
    if (validationFailure != null) {
      state = NotesState(notes: state.notes, failure: validationFailure);
      return;
    }

    state = NotesState(notes: state.notes, isSaving: true);
    final result = await ref
        .read(noteRepositoryProvider)
        .addNote(title: title, body: body);
    if (result.note case final note?) {
      state = NotesState(notes: [note, ...state.notes]);
    } else {
      state = NotesState(notes: state.notes, failure: result.failure);
    }
  }
}
