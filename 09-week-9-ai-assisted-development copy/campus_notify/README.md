# WEEK 9

A feature-first Flutter app with authentication, announcements, push notifications, and local notes.

## Notes search implementation

Notes title search is case-insensitive and ignores surrounding query whitespace. A blank query shows all notes; a non-matching query displays a separate empty state. Search logic is a pure domain use case. The Notes page sends queries to the Riverpod notifier, and the app composition root supplies the SQLite repository implementation.

Relevant structure:

```text
lib/features/notes/
  data/          SQLite database and repository implementation
  domain/        Note entity, repository contract, and use cases
  presentation/  Notes page and Riverpod state notifier
```

The repository contract exposes `fetchNotes()` and `addNote({required title, body})`. Package versions are recorded in `pubspec.yaml`.

## Lab 1: implementation and verification

- Added `filterNotesByTitle` as a pure domain use case. It trims the query, ignores case, and searches titles only.
- Added a search field and a dedicated no-match message to `NotesPage`, while retaining the separate empty-collection message.
- Inspection of the original page showed it rendered all notes and had no state for a non-empty collection with zero search matches. The no-match filter test verifies that `zzz-missing` returns an empty list, and the page renders its dedicated message for that state.
- Tests cover case-insensitive title matches, a no-match query, and a whitespace-only query.

The five-slot Lab 1 prompt is kept separately in [`docs/ai-log.md`](docs/ai-log.md), as requested by the lab.

## Lab 3: debugging and refactoring

### Reproducing the bug

Start `NotesNotifier.load()` with a delayed repository response. Before the response completes, add a note, then complete the load with an older empty result. The note was present after `add` but disappeared when the load completed.

The deterministic regression test `load completion does not discard a note added while loading` failed before the fix:

```text
Expected: ['New note']
Actual:   []
```

`load()` replaced all notifier state with the repository response, even when that response was older than a note added during the request. It now preserves notes added while loading and avoids duplicate IDs. The regression test passes after the change.

The Notes page was split into smaller editor, error, search, and results builders. The notifier calls domain use cases for filtering, loading, and adding. Concrete repository construction is in `main.dart`; SQLite access remains in the data repository.

## AI Challenge: search code review

### Review findings and decisions

1. **Blocker — stale load can hide a note added during the request. Proven true and fixed.** The delayed-fetch regression test failed before the fix with the output above. The notifier now preserves notes added while a fetch is in flight.
2. **Suggestion — presentation constructed the SQLite repository. Proven true and fixed.** `notes_providers.dart` imported the database and repository implementation, making presentation depend on data. Repository construction moved to the app composition root in `main.dart`. No data-layer imports remain under `lib/features/notes/presentation/`.
3. **Suggestion — an empty query should show no results. Rejected.** Clearing search should restore the full note list. The test `empty title query returns every note` verifies the intended behavior, so the filter keeps returning all notes for a blank query.

### Per-file decisions

| File | Decision | Reason |
| --- | --- | --- |
| `lib/features/notes/presentation/pages/notes_page.dart` | Accept | UI sends queries to the notifier and renders state; it has no database calls. |
| `lib/features/notes/presentation/providers/notes_providers.dart` | Accept + refactor | State coordination calls domain use cases; concrete repository construction was removed. |
| `lib/features/notes/domain/usecases/filter_notes.dart` | Accept | Pure title matching trims whitespace, ignores case, and preserves blank-query behavior. |
| `lib/features/notes/domain/usecases/fetch_notes.dart` | Accept | Fetch delegates through the repository contract. |
| `lib/features/notes/domain/usecases/add_note.dart` | Accept | Add delegates through the repository contract. |
| `lib/features/notes/data/repositories/note_repository_impl.dart` | Accept | SQLite access belongs in the data implementation. |
| `lib/main.dart` | Accept + refactor | The app composition root injects the concrete SQLite repository. |
| `test/notes_test.dart` | Accept | Covers notifier search, the load/add race, repository behavior, and failure state. |
| `test/search_filter_test.dart` | Accept | Covers title matching, no match, blank query, and the no-match widget empty state. |

## Refactoring and Testing

### Five-slot prompt context

- **Role:** Senior Flutter developer.
- **Context:** Feature-first notes feature (`presentation -> domain <- data`), Riverpod state, and a SQLite repository. Flutter/Dart constraints and package versions are defined in `pubspec.yaml` (`sdk: ^3.13.2`, `flutter_riverpod: ^3.4.3`, `sqflite: ^2.4.4+2`).
- **Task:** Keep search in a pure domain use case, keep widgets UI-only, and add unit and empty-state widget tests.
- **Limits:** Preserve title-only, case-insensitive matching; a blank query restores all notes. Do not change unrelated features or include secrets.
- **Output:** Small functions/use cases, `test/search_filter_test.dart`, clean analysis, passing tests, and manual verification steps.

Search unit cases live in `test/search_filter_test.dart`: case-insensitive partial match, no match, and blank query. Its widget test verifies that a no-match query displays the empty state and clearing the query restores the note.

## Verification

Run:

```sh
dart format lib test
flutter analyze
flutter test test/search_filter_test.dart
flutter test
```

Latest verification: formatting completed with no changes, `flutter analyze` reported no issues, the focused search tests passed, and the full suite passed all 19 tests.

## Reflection

- **Which AI hallucination did you find, and how did you prove it?** I did not find a fabricated API or package method. I did reject the suggestion that an empty search should show no notes: it contradicted the intended behavior that clearing search restores all notes. The `empty title query returns every note` test verifies that behavior.
- **Which prompt helped most, and what did you change?** The Lab 1 five-slot prompt helped most because it stated the role, project structure and repository contract, task, limits, and expected output. I changed the initial broad request into a focused title-search task with explicit architecture boundaries, three search cases, and manual verification steps.
- **Which refactor did you make to AI code?** I moved search handling behind the notifier and kept matching in a pure domain use case. I also moved SQLite repository construction out of the Notes presentation providers and into the app composition root, and split the Notes page into smaller UI helpers.
- **Which accept/reject decision was hardest?** Rejecting the empty-query suggestion was hardest because returning no results can seem reasonable for a search field. I kept the existing list visible instead, since clearing a filter should restore all notes; the unit test documents that decision.
