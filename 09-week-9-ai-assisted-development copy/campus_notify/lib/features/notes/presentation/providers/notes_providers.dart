import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/failures.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/usecases/add_note.dart';
import '../../domain/usecases/fetch_notes.dart';
import '../../domain/usecases/filter_notes.dart';

final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => throw StateError(
    'Override noteRepositoryProvider in the app composition root.',
  ),
);

final fetchNotesProvider = Provider<FetchNotes>(
  (ref) => FetchNotes(ref.watch(noteRepositoryProvider)),
);
final addNoteProvider = Provider<AddNote>(
  (ref) => AddNote(ref.watch(noteRepositoryProvider)),
);
final filterNotesProvider = Provider<FilterNotes>((ref) => const FilterNotes());

class NotesState {
  const NotesState({
    this.notes = const [],
    this.visibleNotes = const [],
    this.searchQuery = '',
    this.isLoading = false,
    this.isSaving = false,
    this.failure,
  });

  final List<Note> notes;
  final List<Note> visibleNotes;
  final String searchQuery;
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
    final notesBeforeLoad = state.notes;
    state = _copyState(isLoading: true);
    final result = await ref.read(fetchNotesProvider).call();
    final loadedIds = result.notes.map((note) => note.id).toSet();
    final addedDuringLoad = state.notes.where(
      (note) =>
          !notesBeforeLoad.contains(note) &&
          (note.id == null || !loadedIds.contains(note.id)),
    );
    _setNotes(
      [...addedDuringLoad, ...result.notes],
      failure: result.failure,
      isLoading: false,
    );
  }

  void search(String query) {
    final visibleNotes = ref.read(filterNotesProvider).call(state.notes, query);
    state = NotesState(
      notes: state.notes,
      visibleNotes: visibleNotes,
      searchQuery: query,
      isLoading: state.isLoading,
      isSaving: state.isSaving,
      failure: state.failure,
    );
  }

  Future<void> add({required String title, String body = ''}) async {
    state = _copyState(isSaving: true);
    final result = await ref
        .read(addNoteProvider)
        .call(title: title, body: body);
    if (result.note case final note?) {
      _setNotes([note, ...state.notes], isSaving: false);
    } else {
      state = _copyState(isSaving: false, failure: result.failure);
    }
  }

  NotesState _copyState({bool? isLoading, bool? isSaving, Failure? failure}) =>
      NotesState(
        notes: state.notes,
        visibleNotes: state.visibleNotes,
        searchQuery: state.searchQuery,
        isLoading: isLoading ?? state.isLoading,
        isSaving: isSaving ?? state.isSaving,
        failure: failure ?? state.failure,
      );

  void _setNotes(
    List<Note> notes, {
    Failure? failure,
    bool? isLoading,
    bool? isSaving,
  }) {
    state = NotesState(
      notes: notes,
      visibleNotes: ref
          .read(filterNotesProvider)
          .call(notes, state.searchQuery),
      searchQuery: state.searchQuery,
      isLoading: isLoading ?? state.isLoading,
      isSaving: isSaving ?? state.isSaving,
      failure: failure,
    );
  }
}
