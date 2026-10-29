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
| 1 | Confirmed by inspection and search: `NotesPage._addNote` trims and rejects blank input at `07-week-7-clean-architecture/campus_notify/lib/features/notes/presentation/pages/notes_page.dart:31-41`. `NotesNotifier.add` forwards `title` directly at `07-week-7-clean-architecture/campus_notify/lib/features/notes/presentation/providers/notes_providers.dart:41-45`; `NoteRepositoryImpl.addNote` persists it unchanged at `07-week-7-clean-architecture/campus_notify/lib/features/notes/data/repositories/note_repository_impl.dart:31-44`. | **Accept as a real boundary gap; follow-up needed.** | The current page blocks invalid input, but other callers of the public notifier can bypass the rule. Keep UI feedback in the page and return a validation result from a pure feature rule. No implementation change was made during this review exercise. |
| 2 | Confirmed by test inventory/search: `test/notes_test.dart:36-51` has one widget validation case, and it leaves the title field empty. The production code's `.trim()` at `notes_page.dart:32` currently rejects whitespace too, but no test protects that behavior. | **Accept as a test gap.** | Add a whitespace-only submission case and verify no repository write occurs. |
| 3 | Confirmed by test inventory: the widget-level case only covers invalid input; the valid submission test at `test/notes_test.dart:53-73` calls the notifier directly and does not exercise the page's controllers or clearing behavior. | **Accept as a test gap.** | Add a page-level success case that enters a padded title, then checks the saved trimmed title and cleared form. |
| 4 | Rejected by architecture inspection. `notes_providers.dart` is the Riverpod composition point and wires the domain contract to its data implementation. `NoteRepositoryImpl` imports `sqflite` at `07-week-7-clean-architecture/campus_notify/lib/features/notes/data/repositories/note_repository_impl.dart:1`; moving that implementation into domain would make domain depend on a database package. A search under `lib/features/notes/domain` finds no Flutter, SQLite, Dio, Firebase, or repository implementation imports. | **Reject.** | Keep the repository interface in domain and implementation in data. Presentation provider wiring may depend on both to construct the graph. The proposal reverses the dependency rule. |
| 5 | No defect demonstrated. The validation string is a presentation message and is currently displayed by the page. No localization/message system is present in the notes feature. | **Reject the proposed placement; defer centralization.** | Domain should return a typed validation result, not user-facing copy. The page should map that result to UI text. Centralizing copy can wait until the app adds localization or shared message resources. |

## Evidence from project checks

Run from `07-week-7-clean-architecture/campus_notify` on October 29, 2026:

- `flutter analyze` — **Pass**; `No issues found!` (ran in 6.5s).
- `flutter test` — **Pass**; all 14 tests passed, including `empty note title shows validation feedback`.
- `dart format --set-exit-if-changed .` — **Pass**; 32 files checked, 0 changed. The ignored generated `build/` directory was temporarily moved out of the formatter's search because it contains vendored package example sources; it was restored afterward.
- Review searches confirmed that the notifier/repository forward and persist the supplied title without a non-empty check, while `test/notes_test.dart` contains only one widget test and no whitespace-only or valid-title widget cases.

## Final review disposition

The AI review identified a real validation-boundary weakness and two missing widget cases. Its proposed relocation of the data implementation into domain was rejected because it would introduce an SQLite dependency into domain. No code changes were made from these AI suggestions in this challenge; the accepted items remain follow-up work. This note is an AI self-review record, not a human approval of the open PR.
