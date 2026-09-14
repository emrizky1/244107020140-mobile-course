# Navigation

---

## Screenshot

### Home Screen
![Home Screen](<screenshot/Screenshot 2026-09-14 at 21.38.18.png>)

### Detail Screen
![Detail Screen](<screenshot/Screenshot 2026-09-14 at 21.38.34.png>)

---

# ToDo

---

## Screenshot

### Add ToDo
![Add ToDo](<screenshot/Screenshot 2026-09-14 at 21.40.10.png>)

### Complete ToDo
![Complete ToDo](<screenshot/Screenshot 2026-09-14 at 21.41.39.png>)

---

# Async

---

## Screenshot

### Loading State
![Loading State](<screenshot/Screenshot 2026-09-14 at 21.42.50.png>)

*The system shows a loading screen before displaying the data.*

### Error State
![Error State](<screenshot/Screenshot 2026-09-14 at 21.44.30.png>)

*This is what happens after throwing an exception: it displays the error message and a retry button.*

### Revert / Success State
![Success State](<screenshot/Screenshot 2026-09-14 at 21.45.06.png>)

*After removing the thrown exception, the data is successfully loaded.*

---

## Reflection

### 1. Why Is Showing Old Data Better Than Blanking the Screen?

Replacing the whole page with a full-screen spinner (`CircularProgressIndicator`) creates a pretty jarring experience if the app already has data. Keeping the old data visible helps because:

* **Prevents screen flickering (*layout shift*):** Wiping the screen clean and rebuilding it a second later makes the UI jump around. Keeping the old list in place makes the refresh feel completely seamless.
* **Feels much faster (*perceived performance*):** Staring at a blank screen makes the app feel slow or frozen. If the old items stay visible, the app feels responsive while the network request runs in the background.
* **Keeps scroll position intact:** Wiping the screen resets the list view back to the top. If a user was scrolled halfway down, losing their spot is super annoying.
* **Acts as a fallback if the request fails:** If the connection drops during a refresh, wiping the screen leaves the user staring at an ugly full-page error. With stale data, the user can still view the previous list, and the app just needs to show a quick `SnackBar` saying the update failed.

---

### 2. When Does This Pattern Matter Most?

This approach is especially critical in cases like:

* **Pull-to-Refresh:** When a user pulls down to check for new items, they expect the current list to stay put while the top spinner animates.
* **Social Media & News Feeds:** Apps like X (Twitter) or Instagram never clear your feed when checking for new posts; you can keep reading while new content loads above.
* **Spotty Mobile Networks:** On unstable connections, stale data acts as an instant offline cache so the app stays functional.
* **Periodic Auto-Polling:** If an app auto-refreshes every 30 seconds (like crypto prices or order tracking), flashing a loading spinner on every single tick would be unusable.

---

# AI Challenge

## Prompt
> Create a Flutter page named `StatsPage` using `flutter_riverpod`.  
> **Requirements:**  
> - `ConsumerWidget` with an `AsyncNotifierProvider` that simulates fetching statistical data (2-second delay, occasional 30% failure rate).  
> - UI must handle loading (spinner), error (message + retry button), and success (`ListView` with 3 items).  
> - Provide unit tests for the notifier.  
> - Explain each part of the code in comments.  

---

## Screenshot

### StatsPage UI
![StatsPage UI](<screenshot/Screenshot 2026-09-14 at 21.46.20.png>)

*The `StatsPage` interface running on the iOS simulator, successfully rendering 3 statistics items using Riverpod `AsyncNotifierProvider`.*

---

## AI Verification Checklist

Below is the verification report for the AI-generated code located in the `AI_challenge` directory:

| No | Verification Criteria | Status | Summary of Findings |
|:---:|:---|:---:|:---|
| 1 | **Immutable State** (no direct mutation) | Passed | `StatItem` is immutable (`final` fields) and state is replaced functionally via `AsyncValue.guard`. |
| 2 | **Proper `ref.watch` vs `ref.read` Usage** | Passed | `ref.watch` is exclusively used inside `build()`; `ref.read` is used in event callbacks and internal notifier methods. |
| 3 | **All 3 `AsyncValue` States Handled** | Passed | Fully handles `loading` (spinner), `error` (message + retry button), and `data` (3-item `ListView`) via `statsAsync.when()`. |
| 4 | **Explicit & Unique Provider Declarations** | Passed | Providers are declared with explicit generic types (`Provider<Duration>`, `Provider<bool Function()>`, `AsyncNotifierProvider<StatsNotifier, List<StatItem>>`) without duplicates. |
| 5 | **No Legacy APIs / Antipatterns** | Passed | Built using modern Riverpod 2.0+ / 3.0+ architecture (`AsyncNotifier` & `ConsumerWidget`), free of obsolete `StateNotifierProvider` or `StateProvider`. |
| 6 | **`flutter analyze` & `flutter test` Results** | Passed | 0 issues/warnings in `flutter analyze`, and all 6/6 unit tests pass cleanly. |

---

### Detailed Verification Findings

#### 1. Is state modified immutably (no `state.add()` or direct list mutation)?
- **Status: Passed**
- **Findings & Evidence:**
  - `StatItem` has only `final` fields and a `const` constructor.
  - `fetchStats()` returns fresh list instances rather than mutating an existing collection in place.
  - `retry()` updates state functionally using `AsyncValue.guard()`—no `.add()`, `.clear()`, or in-place updates.

#### 2. Is `ref.watch` only used inside `build`, and `ref.read` in callbacks?
- **Status: Passed**
- **Findings & Evidence:**
  - `ref.watch(statsProvider)` is used exclusively inside `StatsPage.build()` for reactive UI rebuilds.
  - `ref.read` is confined to the retry button's `onPressed` handler and one-off configuration reads inside `fetchStats()`.

#### 3. Are all three `AsyncValue` states actually handled (not just success)?
- **Status: Passed**
- **Findings & Evidence:**
  - Handled via `statsAsync.when(...)` in `StatsPage`:
    - **Loading:** Shows a centered `CircularProgressIndicator` with status text.
    - **Error:** Displays the error message alongside a functional retry button.
    - **Data:** Renders the list using `ListView.separated`.

#### 4. Are providers declared with explicit types and without duplicates?
- **Status: Passed**
- **Findings & Evidence:**
  - All providers are top-level constants with explicit types:
    - `fetchDelayProvider` → `Provider<Duration>`
    - `shouldFailProvider` → `Provider<bool Function()>`
    - `statsProvider` → `AsyncNotifierProvider<StatsNotifier, List<StatItem>>`
  - No duplicated responsibilities or naming collisions.

#### 5. Does the AI code use legacy Riverpod APIs (StateProvider antipattern, obsolete StateNotifierProvider, or unnecessary nested Consumers)?
- **Status: Passed**
- **Findings & Evidence:**
  - Built with modern `AsyncNotifier` and `AsyncNotifierProvider` instead of legacy `StateNotifierProvider` or `StateProvider`.
  - Extends `ConsumerWidget` directly to access `WidgetRef`, avoiding redundant nested `Consumer` widgets.

#### 6. When running `flutter analyze` and `flutter test`, does the AI output pass without warnings?
- **Status: Passed**
- **Findings & Evidence:**
  - `flutter analyze`: 0 issues found.
  - `flutter test`: 6/6 tests passed (covering model equality, loading states, successful fetch, failure handling, and retry).

---

# Refactoring

---

## Screenshot

### All Tasks View (Semua)
![All Tasks](<screenshot/Screenshot 2026-09-14 at 22.44.07.png>)

*The refactored `TodoPage` displaying all tasks using the newly extracted `TodoTile` widget and segmented filter buttons (`Semua`, `Aktif`, `Selesai`).*

### Filtered Active Tasks (Aktif)
![Filtered Active Tasks](<screenshot/Screenshot 2026-09-14 at 22.44.23.png>)

*Active tasks filtered dynamically using the derived `filteredTodoListProvider`.*

### Statistics Page (`/stats`)
![Stats Page](<screenshot/Screenshot 2026-09-14 at 22.44.37.png>)

*The `/stats` destination accessed seamlessly via the Material 3 `NavigationBar` integrated through `GoRouter`'s `StatefulShellRoute`.*

---

# Testing

---

## Screenshot

### Unit Tests & Analysis Output
![Test and Analysis Results](<screenshot/Screenshot 2026-09-14 at 22.48.54.png>)

*Terminal execution verifying that `flutter test` passed all test cases and `flutter analyze` reported 0 issues/warnings.*

---

# Final Reflection

### 1. When is `setState` still sufficient, and when should state be lifted up to Riverpod?

Use **`setState`** for simple UI state used by one widget, like dropdowns, animations, or focus. If it can reset when leaving the screen, `setState` is usually enough.

Lift state to **Riverpod** when:
* **Multiple screens need the data:** For example, a list and dashboard sharing the same data.
* **Data must survive navigation:** The data shouldn't disappear when the widget is removed.
* **Handling async or business logic:** API calls, storage, and caching are better handled in Notifiers.
* **Testing:** Notifiers can be tested without building the widget tree.

---

### 2. What is the difference between `context.go` and `context.push`, and when is each appropriate to use?

The difference comes down to whether you are replacing the navigation location or just stacking a screen on top:

* **`context.go` (navigates by route):** Resolves the target path based on your route configuration, resetting the stack to match that URL.
  * *Use it for:* Top-level tabs (like a `NavigationBar`), deep link handling, or post-login redirects where the user shouldn't be able to press "back" into the login screen.

* **`context.push` (stacks on top):** Pushes a new screen directly on top of the current view, keeping the previous screen underneath with an automatic back button.
  * *Use it for:* Detail pages, sub-settings, or multi-step forms where the user expects to pop right back to where they started.

---

### 3. How does `AsyncValue` prevent bugs compared to three separate booleans?

Managing separate flags (`isLoading`, `hasError`, `data`) is error-prone because it's too easy to forget to reset one. You end up in messy, impossible states—like showing a loading spinner and an error banner at the exact same time.

`AsyncValue` fixes this by turning asynchronous state into a single, mutually exclusive value:

* **No impossible states:** The UI can only be in one state at a time (loading, error, or data). You physically cannot render conflicting screens.
* **Compile-time safety:** Methods like `.when()` force you to handle all three cases, meaning you won't accidentally forget an error or empty state.
* **Smoother refetches:** It handles background reloading out of the box by keeping previous data visible while fetching, so you don't need extra flags to prevent UI flicker.

---

### 4. Which parts of the AI-generated code did you fix/improve, and why?

* No changes were required. The generated code followed all prompt requirements out of the box.