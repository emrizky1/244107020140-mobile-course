import '../entities/note.dart';

/// Returns notes whose titles contain [query], ignoring case and whitespace.
List<Note> filterNotesByTitle(List<Note> notes, String query) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) return notes;

  return notes
      .where((note) => note.title.toLowerCase().contains(normalizedQuery))
      .toList(growable: false);
}

class FilterNotes {
  const FilterNotes();

  List<Note> call(List<Note> notes, String query) =>
      filterNotesByTitle(notes, query);
}
