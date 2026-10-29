# AI review vs. decision

## Prompt used

```text
Review this Flutter PR as a senior Flutter dev.
Context: feature-first Clean Architecture
(presentation -> domain <- data), Riverpod, GoRouter, SQLite + Dio.
Focus: correctness, architecture, tests. Ignore style.
Give the top 5 findings + severity (blocker/suggestion)
+ rationale + proposed code fix.
```

## Raw AI review output

1. **Suggestion — correctness:** The non-empty-title rule exists only in `NotesPage._addNote`. `NotesNotifier.add` and `NoteRepositoryImpl.addNote` accept the title without checking it, so another caller can persist an empty or whitespace-only title. Add a pure validation rule at the feature boundary (for example, a validator/use case or notifier result) and keep the SnackBar in presentation.
2. **Suggestion — tests:** The new widget test submits only an exactly empty string. The page trims input, so add a whitespace-only widget case and assert that feedback appears and the repository is untouched.
3. **Suggestion — tests:** There is no successful `NotesPage` submission test. Add a widget case for a padded valid title and verify the saved title is trimmed and the form clears; the existing notifier test does not exercise the page controllers.
4. **Suggestion — architecture:** `notes_providers.dart` imports `NoteRepositoryImpl`, which I read as a data dependency leaking into the feature. Move `NoteRepositoryImpl` into `domain` so the presentation provider can resolve it without importing data.
5. **Suggestion — correctness:** The new validation copy is a literal in the page. Put the message in the domain validation result so every caller receives the same feedback.

## Verification and final decisions

| # | Verification | Decision | Technical rationale |
|---|---|---|---|
| 1 | Confirmed by inspection and search: `NotesPage._addNote` trims and rejects blank input at `07-week-7-clean-architecture/campus_notify/lib/features/notes/presentation/pages/notes_page.dart:31-41`. Before the fix, `NotesNotifier.add` forwarded `title` directly and the repository persisted it unchanged. | **Accept and fix.** | Added a pure domain validator and call it from both the page and notifier. The notifier now returns a `ValidationFailure` without calling the repository; the page keeps the SnackBar in presentation. |
| 2 | Confirmed by test inventory/search: the original widget validation case submitted only an empty string. | **Accept and fix.** | Added a whitespace-only widget test that verifies feedback and no repository write. |
| 3 | Confirmed by test inventory: the original valid submission test called the notifier directly and did not exercise the page controllers. | **Accept and fix.** | Added a page-level success test for padded title/body input, trimmed persistence, and cleared form fields. |
| 4 | Rejected by architecture inspection. `notes_providers.dart` is the Riverpod composition point and wires the domain contract to its data implementation. `NoteRepositoryImpl` imports `sqflite` at `07-week-7-clean-architecture/campus_notify/lib/features/notes/data/repositories/note_repository_impl.dart:1`; moving that implementation into domain would make domain depend on a database package. A search under `lib/features/notes/domain` finds no Flutter, SQLite, Dio, Firebase, or repository implementation imports. | **Reject.** | Keep the repository interface in domain and implementation in data. Presentation provider wiring may depend on both to construct the graph. The proposal reverses the dependency rule. |
| 5 | Confirmed as a reuse concern once the notifier also validates. The text is now shared through the validation result. | **Accept and fix.** | The pure domain validator returns a typed `ValidationFailure`; both notifier state and the page's SnackBar use its message. This matches the project's existing `Failure` pattern. |

## Evidence from project checks

Initial review evidence, run from `07-week-7-clean-architecture/campus_notify` on October 29, 2026:

- `flutter analyze` — **Pass**; `No issues found!` (ran in 6.5s).
- `flutter test` — **Pass**; all 14 tests passed, including `empty note title shows validation feedback`.
- `dart format --set-exit-if-changed .` — **Pass**; 32 files checked, 0 changed. The ignored generated `build/` directory was temporarily moved out of the formatter's search because it contains vendored package example sources; it was restored afterward.
- Review searches confirmed that the original notifier/repository forwarded and persisted the supplied title without a non-empty check, while the original `test/notes_test.dart` contained only one widget validation case.

## Refactoring follow-up evidence

After the accepted findings were addressed:

- Added `features/notes/domain/validation/note_title_validator.dart`; it has no Flutter, SQLite, Dio, Firebase, or UI imports.
- The notifier rejects a blank title before repository access. Widget tests cover empty input, whitespace-only input, and a successful padded title/body submission; a provider test verifies direct notifier calls cannot save blank titles.
- `flutter analyze` — **Pass**; no issues found.
- `flutter test` — **Pass**; all 17 tests passed.
- `dart format --set-exit-if-changed .` — **Pass**; 33 app files checked, 0 changed. The ignored generated `build/` directory was temporarily moved out of the formatter's search and restored afterward.
- Manual validation and screenshot — **Pending**; the macOS app build stalled while fetching Firebase Swift Package Manager dependencies, and no other Flutter device is connected.

## Final review disposition

The AI review identified a real validation-boundary weakness and two missing widget cases; those were fixed and covered by tests. Its proposal to move the data implementation into domain was rejected because it would introduce an SQLite dependency into domain. The PR still needs a manual run with screenshot evidence and formal peer re-review/approval. This note is an AI self-review record, not a human approval of the open PR.
