# Flutter Performance Optimization Report

## 1. Overview

This report documents performance improvements applied to the Notes feature of the Campus Notify application.

The optimization focuses on reducing unnecessary widget construction, limiting widget rebuilds, and improving widget code organization.

## 2. Implemented Optimizations

### 2.1 Lazy List Rendering

- **Location:** `lib/features/notes/presentation/pages/notes_page.dart`
- **Before:** Notes were rendered using `Column` and `.map().toList()`.
- **After:** Replaced the implementation with `SliverList.builder`.
- **Reason:** Lazy rendering constructs list items when they are needed instead of constructing all items at once.

### 2.2 Selective Widget Rebuilds

- **Location:** `lib/features/notes/presentation/pages/notes_page.dart`
- **Before:** The entire NotesPage watched the complete `notesProvider` state.
- **After:** Used Riverpod `select()` to listen only to the state properties required by individual UI sections.
- **Reason:** Prevents unrelated UI sections from rebuilding when only specific state properties change.

### 2.3 Widget Extraction

- **Location:** `lib/features/notes/presentation/pages/notes_page.dart`
- **Before:** Note card UI was defined directly inside the list builder.
- **After:** Extracted the note card into a separate `NoteCard` StatelessWidget.
- **Reason:** Improves component separation, readability, and maintainability while keeping each note item independently structured.

## 3. Profiling Findings

The application was inspected using Flutter DevTools in Profile mode.

Observations during testing:

- A UI frame of approximately 27.5 ms was observed in one profiling session.
- Raster time was approximately 4.9 ms in that observation.
- A Paint event of approximately 0.6 ms was observed.
- Repeated search input and deletion sometimes coincided with red/janky frames.
- Temporary increases in Matrix4 and Vector4 instances were observed in the Memory tab. Their counts later decreased, so these observations alone do not establish a memory leak.

These observations are not a controlled benchmark and should not be interpreted as proof of a specific optimization's performance gain.

## 4. Before and After Evidence

Screenshots captured during profiling:

- Before optimization: `screenshots/before-profile.png`
- After optimization: `screenshots/after-profile.png`

The screenshots provide visual profiling evidence. Exact average frame time, total janky frame count, and heap usage values were not consistently recorded; therefore, no numerical improvement is claimed.

## 5. Code Quality Verification

The following checks were performed after the code changes:

| Check | Result |
|---|---|
| `dart format` | Completed |
| `flutter analyze` | No issues found |
| `flutter test` | All 33 tests passed |

## 6. Reflection

### 1. Which optimization had the biggest impact and why?

Lazy list rendering is expected to have the most direct impact when displaying a large number of notes because it avoids constructing every list item at once.

### 2. How can we verify that optimizations actually work?

Use Flutter DevTools in Profile mode to compare the same user interactions before and after optimization. Observe UI and Raster frame times, janky frames, and memory usage under consistent conditions.

### 3. What are the trade-offs?

Selective rebuilds require more careful state selection. Extracting widgets introduces additional components and files or classes to maintain. Lazy rendering also requires using slivers or builder-based list structures instead of eagerly constructing all children.

### 4. When should premature optimization be avoided?

Optimization should be based on measurable performance problems. Developers should first identify bottlenecks through profiling instead of adding complexity to code that already performs adequately.
