
## Reflection

### 1. Which optimization had the biggest impact and why?

Lazy list rendering using `SliverList.builder` has the most direct potential impact, especially when handling a large number of notes. It builds list items on demand instead of constructing all note widgets at once, reducing unnecessary widget construction.

### 2. How did you verify that the optimizations actually work (not placebo)?

I used Flutter DevTools in Profile mode to inspect application performance and compare profiling sessions before and after optimization. I also ran `flutter analyze` and `flutter test` to verify code quality and functionality. All 33 tests passed, and static analysis reported no issues. However, exact before-and-after performance metrics were not consistently recorded, so a specific numerical performance improvement cannot be claimed.

### 3. What trade-offs did you face?

The optimizations introduced some additional code organization and state-management considerations. Riverpod `select()` requires careful selection of state properties, while extracting `NoteCard` adds a separate component to maintain. Using `SliverList.builder` also requires a sliver-based layout structure. These trade-offs improve code organization and can reduce unnecessary work, but add some implementation complexity.

### 4. When should premature optimization be avoided?

Premature optimization should be avoided when there is no measurable performance problem. Developers should first profile the application, identify actual bottlenecks, and prioritize optimizations that address those bottlenecks instead of adding unnecessary complexity.
