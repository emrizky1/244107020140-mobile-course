# Lab 1 prompt

**Role:** Senior Flutter developer.

**Context:** This is a feature-first Flutter app. Notes code lives in `lib/features/notes/{presentation,domain,data}`. The `NoteRepository` contract in `domain/repositories/note_repository.dart` exposes `fetchNotes()` and `addNote({required title, body})`; the data implementation stores notes with SQLite. Dependencies in `pubspec.yaml`: Dart SDK `^3.13.2`, `flutter_riverpod: ^3.4.3`, `sqflite: ^2.4.4+2`, and `flutter_test` for tests. No credentials or secrets are needed.

**Task:** Add notes title search with a clear empty state for queries that match no note titles.

**Limits:** Preserve the feature-first architecture and repository contract. Keep database calls out of widgets and search rules in the domain layer. Keep the implementation focused (no more than 80 lines of new code), and do not change unrelated behavior.

**Output:** Provide the code, three search test cases, and instructions for running the tests and manually checking empty query, match, and no-match behavior.
