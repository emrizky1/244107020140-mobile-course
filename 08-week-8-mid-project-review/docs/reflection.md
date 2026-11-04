# Reflection

## Responsible approval

A blind LGTM says only that the reviewer saw the diff. A responsible approval follows the code path, checks edge cases and layer boundaries, runs the tests, and verifies the user-visible behavior. A blind approval can let data loss, invalid state, or architecture debt reach the shared branch, leaving the team to debug it later.

## Request changes or suggestion

Use **Request changes** when a demonstrated issue can cause incorrect behavior, data loss, a broken dependency rule, missing required coverage, or a failed acceptance criterion. Use a **suggestion** for a useful but non-blocking improvement such as a naming or extraction idea. State the observation, its impact, and a concrete next step so the author can act without guessing.

## AI review decision

The AI correctly identified that UI-only validation could be bypassed through `NotesNotifier.add`, and that whitespace-only and successful widget flows lacked coverage. Those points were verified against the notifier, repository, and original test file, then addressed with a shared pure validator and widget/provider tests.

I rejected the AI proposal to move `NoteRepositoryImpl` into `domain`. That implementation imports `sqflite`, so the change would make domain depend on a data-layer package. The repository contract stays in domain, its implementation stays in data, and the Riverpod provider remains the composition point. The full prompt, raw review, evidence, and decision table are in [`ai-review-vs-decision.md`](ai-review-vs-decision.md).

## Fix after peer feedback

I added whitespace-only and valid-title widget tests and enforced the shared title rule in the notifier. This proves both the user-facing feedback and the no-save behavior for invalid titles, including callers that bypass the page. The local analysis and all 17 tests pass. Formal peer re-review/approval and manual screenshot evidence are still pending.
