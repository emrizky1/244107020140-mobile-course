# Lab: Test Suite for the Notes Feature

Feature under test: **Notes** (add a note, list notes, search by title) in
`lib/features/notes/`. It is split into a domain layer (`Note`, `NoteRepository`,
use cases), a data layer (`NoteModel`, `NoteRepositoryImpl` on sqflite) and a
presentation layer (`NotesNotifier`, `NotesPage`).

## 1. Behavior scenarios

| # | Type | Scenario | Expected behavior |
|---|------|----------|-------------------|
| 1 | Happy path | User enters a title and body and taps **Add note** | The note appears at the top of the list, is marked `Local`, and the form is cleared |
| 2 | Edge case | User taps **Add note** with an empty or whitespace-only title | Nothing is saved, the repository is never called, the list is unchanged |
| 3 | Edge case | User searches with different casing, extra spaces, or a text that matches only a note body | Only titles are matched, ignoring case and surrounding spaces; no match shows "Tidak ada judul catatan yang cocok." and clearing the search restores the list |
| 4 | Failure | Saving fails (database error) | An error message and a retry button are shown, the list is unchanged, and the typed text is kept |
| 5 | Failure | Loading fails (database cannot be opened) | The repository returns an empty list and a `LocalFailure`, which the state exposes; a later successful load clears the error |
| 6 | State | A save is still in progress | The button is disabled and a spinner is shown until the repository answers |
| 7 | Main flow | Add a note, search for it, close and reopen the app | The note survives a restart because it was written to the database |

## 2. Test map

| Lab step | File | What it covers (scenario #) |
|----------|------|-----------------------------|
| Test the logic | `test/notes_logic_test.dart` | `filterNotesByTitle` rules (3) and `NoteModel` mapping, including null columns and a corrupt date. Cases are grouped with `group` |
| Test a dependency | `test/helpers/fake_note_repository.dart`, `test/notes_notifier_test.dart` | Fake repository for success and error; notifier add/load behavior (1, 4, 5, 6); `NoteRepositoryImpl` returning `LocalFailure` when the database fails (5) |
| Test the UI | `test/notes_page_test.dart` | Initial display and loading state, blank title, successful add, save failure, disabled button while saving (1, 2, 4, 6) |
| Test the main flow | `integration_test/app_test.dart` | Add, search and restart against a real in-memory sqflite database (1, 3, 7) |

Existing tests (`test/notes_test.dart`, `test/search_filter_test.dart`) are left as they were.

Small production changes made only to make the UI testable: stable `Key`s on the
title field, body field, search field and add button in `notes_page.dart`
(`note-title-field`, `note-body-field`, `note-search-field`, `add-note-button`),
and the `integration_test` SDK package under `dev_dependencies` in `pubspec.yaml`.

## 3. Run the checks

```bash
flutter pub get
flutter test
flutter test integration_test/app_test.dart -d <device_id>
flutter analyze
```

List device ids with `flutter devices`. Optional coverage report:
`flutter test --coverage`.

## 4. Results

Fill this in after running the commands above.

- [ ] `flutter test`: all tests pass
- [ ] `flutter test integration_test/app_test.dart -d <device_id>`: passes
- [ ] `flutter analyze`: no issues

If a test fails, read which test failed and which expectation was not met, then
rule out test order, shared data, and network dependence before changing code.
