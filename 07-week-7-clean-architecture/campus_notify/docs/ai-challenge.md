# AI Challenge — Architecture proposal review

## Challenge prompt

```text
My Flutter project: campus_notify (auth + FCM + announcement list).
Current state: lib/{data, providers, pages, messaging} folders,
repositories mixed with implementations, widgets calling Dio directly.
Tasks:
1. Propose a feature-first Clean Architecture structure
   (presentation/domain/data) for the auth + announcements features.
2. For each old file, state its new destination (move/split/delete).
3. Flag what would be over-engineering if applied to simple CRUD,
   and when a use case is truly needed vs repository straight to notifier.
4. Show the Riverpod DI wiring (no extra DI package).
Explain the trade-off of every decision.
```

## Initial AI proposal

The initial proposal was to organize code by feature, with `domain`, `data`, and `presentation` inside each feature. Domain would own entities and repository contracts; data would own models and implementations; presentation would own pages and Riverpod state. Shared failures and routing would live under `core` and `routing`.

It also proposed a use case for each operation (`GetNotes`, `AddNote`, and `Login`), with feature providers wiring implementations to contracts. Model mapping would stay out of entities, and widgets would read state and dispatch actions without constructing repositories or touching storage/network APIs.

This was a starting proposal, not the final architecture. The use-case-per-operation recommendation was too broad for the Notes feature's simple local CRUD.

## Proposal versus final decision

| Topic | Initial proposal | Final decision | Trade-off and reason |
|---|---|---|---|
| Feature boundaries | Feature-first `auth`, `announcements`, and `notes` folders, each split by layer | Kept feature-first. The existing notification feature is named `notifications` because it owns FCM, topic subscription, and announcement navigation. | Related changes stay together as the project grows; small shared concerns such as failures and route constants remain in `core` and `routing`. |
| Repository boundary | Contract in domain, implementation in data | Kept this split for auth, notes, and notifications. | Domain and presentation can depend on contracts; data can change from mock/SQLite/Firebase implementations without changing widgets. It adds files, but the persistence and platform boundaries justify them. |
| Use cases | Add one for every operation | Kept `Login`, removed Notes `GetNotes` and `AddNote`. Notes state calls its repository directly for basic local CRUD. `Login` validates credentials before invoking the auth contract. | A one-line CRUD wrapper adds navigation without business behavior. Login has a domain validation rule; a use case gives that rule a pure-Dart home. Add a use case later if note operations gain validation, sync, or multi-repository work. |
| Entity/model mapping | Keep entities pure, perform map/JSON/SQLite mapping in data models | Kept. `Note` has no mapping methods; `NoteModel` owns SQLite map and date conversion. | Prevents persistence details from leaking into domain at the cost of a small adapter class. |
| Dependency injection | Riverpod providers, no extra DI package | Kept. Auth, Notes, and Notifications each have provider files that wire contracts to implementations. Startup reads `apiClientProvider` after Firebase initialization. | Riverpod is already present, so a second DI package would add setup and concepts without improving this app. |
| Failures | Return typed failure values rather than leaking data exceptions | Kept for repository operations. SQLite exceptions become `LocalFailure`; the UI renders the message and can retry. | Explicit results need a little more state handling, but preserve a clean boundary and avoid passing database exceptions into widgets. |
| Routing and app setup | Keep routing and startup composition outside feature data/domain | Kept. `routing/routes.dart` owns paths; `main.dart` initializes Firebase and the router. | The composition root necessarily knows platform startup details, while feature code stays focused. |

## Old file destinations

| Original file | Final destination / action |
|---|---|
| `lib/pages/home_page.dart` | `lib/features/notifications/presentation/pages/home_page.dart` |
| `lib/pages/login_page.dart` | `lib/features/auth/presentation/pages/login_page.dart` |
| `lib/pages/announcement_page.dart` | `lib/features/notifications/presentation/pages/announcement_page.dart` |
| `lib/providers/auth_provider.dart` | `lib/features/auth/presentation/providers/auth_provider.dart` |
| `lib/data/auth_repository.dart` | Split into the domain contract `lib/features/auth/domain/repositories/auth_repository.dart`, implementation `lib/features/auth/data/repositories/auth_repository_impl.dart`, and entity `lib/features/auth/domain/entities/auth_session.dart` |
| `lib/data/token_store.dart` | `lib/features/auth/data/token_store.dart` |
| `lib/data/api_client.dart` | `lib/features/auth/data/api_client.dart` |
| `lib/data/api_errors.dart` | `lib/core/api_errors.dart` |
| `lib/messaging/push_service.dart` | `lib/features/notifications/data/services/push_service.dart` |
| `lib/routes.dart` | `lib/routing/routes.dart` |
| `lib/main.dart` | Kept as the application composition/startup root; it no longer constructs auth implementations directly. |
| Notes `GetNotes` and `AddNote` wrappers | Deleted after review; basic CRUD now flows from `NotesNotifier` to the injected `NoteRepository`. |

## Dependency direction

```text
presentation  ->  domain
data          ->  domain
main / providers compose concrete data implementations behind domain contracts
```

Domain imports no Flutter, Dio, SQLite, Firebase, or secure-storage packages. Data models translate external representations into domain entities. Widgets do not instantiate repository implementations.

## Verification record

Commands and results from the final architecture review:

1. Presentation contains no raw network/database/storage access:

   ```text
   rg -n 'Dio\(|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences\.getInstance|FirebaseMessaging|FirebaseAuth' lib/features/*/presentation
   Result: zero hits.
   ```

2. Domain contains no framework/data package imports:

   ```text
   rg -n "package:flutter/|package:dio/|package:sqflite/|package:firebase|package:flutter_secure_storage/" lib/features/*/domain
   Result: zero hits.
   ```

3. Pages do not construct repository implementations or clients:

   ```text
   rg -n 'RepositoryImpl\(|Dio\(BaseOptions|openDatabase' lib/features/*/presentation/pages
   Result: zero hits.
   ```

Static analysis and tests for this review:

- `flutter analyze`: **No issues found**.
- `flutter test`: **All 13 tests passed** after subsequent refactoring labs.
