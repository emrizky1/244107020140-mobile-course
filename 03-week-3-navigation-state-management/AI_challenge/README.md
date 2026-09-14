# Stats App (AI Challenge)

A Flutter project demonstrating asynchronous state management with modern Riverpod (`flutter_riverpod` v3.x), implementing `AsyncNotifier` and `ConsumerWidget`.

## Features
- **AsyncNotifier & AsyncNotifierProvider:** Simulates asynchronous stats fetching with simulated latency (2 seconds) and a 30% failure rate.
- **Dependency Injection for Testing:** Overridable `fetchDelayProvider` and `shouldFailProvider` to make unit testing deterministic and fast.
- **Three-State Handling:** Complete handling of `loading`, `error`, and `data` states via `AsyncValue.when()`.
- **Unit Tests:** 100% passing tests for model equality, initial loading state, successful data fetching, simulated error handling, and retry logic.

## Project Structure
```
AI_challenge/
├── lib/
│   ├── main.dart                      # App entry point with ProviderScope
│   ├── notifiers/
│   │   └── stats_notifier.dart        # StatItem model & StatsNotifier (AsyncNotifier)
│   └── pages/
│       └── stats_page.dart            # StatsPage UI (ConsumerWidget)
└── test/
    └── notifiers/
        └── stats_notifier_test.dart   # Unit tests using ProviderContainer
```

## Running the Application & Tests

To analyze the code:
```bash
flutter analyze
```

To run all unit tests:
```bash
flutter test
```

For the complete verification checklist and reflections, see the [main README](../README.md).
