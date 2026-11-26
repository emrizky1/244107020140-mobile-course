# Performance Findings

## Issue 1: Inefficient List Rendering

- **Location:** `lib/features/notes/presentation/pages/notes_page.dart`
- **Problem:** The application uses `Column` combined with `.map().toList()` to generate note widgets.
- **Impact:** All note widgets are constructed at once, even when they are outside the visible screen area. This can increase widget construction and layout costs as the number of notes grows.
- **Proposed Optimization:** Replace the current implementation with `ListView.builder` to support lazy widget construction.

## Issue 2: Unnecessary Widget Rebuilds

- **Location:** `lib/features/notes/presentation/pages/notes_page.dart`
- **Problem:** The entire NotesPage watches the complete `notesProvider` state. Every search query updates the state and can trigger a rebuild of the entire page.
- **Impact:** Unrelated UI components may be rebuilt when only the search results change.
- **Proposed Optimization:** Extract independent widgets and use Riverpod `select()` to listen only to the state properties required by each widget.

## Issue 3: Unmanaged StreamSubscription

- **Location:** `lib/features/notifications/presentation/pages/home_page.dart`
- **Problem:** The stream subscription created using `notifications.tokenRefreshes.listen()` is not stored or explicitly cancelled.
- **Impact:** The listener may remain active after the HomePage is disposed, potentially retaining resources unnecessarily.
- **Proposed Optimization:** Store the StreamSubscription and cancel it inside the State's `dispose()` method.

## Verification

The identified issues will be further evaluated using Flutter DevTools Performance and Memory profiling before and after optimization.