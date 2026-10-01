# AI Challenge — Storage Comparison for Flutter Offline Notes

## Prompt Used

```
Flutter Offline Notes app: note CRUD + theme preference.
Compare SharedPreferences, Hive, sqflite (SQLite), and Drift
for these two needs. Requirements:
- Criteria: query complexity, relational needs, reactivity (streams),
  type-safety, boilerplate size, and testability.
- Give a final recommendation: which for preferences, which for notes,
  with reasons in one table.
- Show the table/box schema for 1000+ notes.
  Explain the trade-off of each choice.
```

---

## 1. Initial AI Output — Full Comparison

### Overview of Each Option

| Storage | Type | Description |
|---------|------|-------------|
| **SharedPreferences** | Key-value (platform XML/plist) | Thin wrapper over Android SharedPreferences / iOS NSUserDefaults. Designed for small, flat primitives (bool, int, String). |
| **Hive** | Key-value / NoSQL (binary box) | Pure-Dart, zero-dependency binary store. Fast reads via in-memory index. No SQL, no relations. |
| **sqflite** | Relational SQL (SQLite) | Direct SQLite bindings. Full SQL power: joins, indexes, aggregates, migrations. Raw string queries. |
| **Drift** | Relational SQL (SQLite) with codegen | Type-safe wrapper over SQLite. Generates Dart code from table definitions. Provides streams, DAOs, and compile-time query validation. |

### Criteria Comparison Table

| Criteria | SharedPreferences | Hive | sqflite (SQLite) | Drift |
|----------|:-:|:-:|:-:|:-:|
| **Query complexity** | [X] None — get/set by key only | [~] Limited — filter in Dart, no SQL | [V] Full SQL — WHERE, JOIN, GROUP BY, subqueries | [V] Full SQL — same power as sqflite, type-checked at compile time |
| **Relational needs** | [X] No relations | [X] No relations (manual linking via keys) | [V] Foreign keys, JOINs, indexes | [V] Same as sqflite + codegen enforces schema |
| **Reactivity (streams)** | [X] No streams — poll only | [~] `box.watch()` per key, not per query | [~] No built-in streams — must wrap with `StreamController` manually | [V] Built-in `watch()` on any query — auto-emits on data change |
| **Type-safety** | [X] Strings for keys, runtime casts | [~] TypeAdapters needed, but no query-level safety | [X] Raw SQL strings — typos found only at runtime | [V] Compile-time checked — table schema, column types, query results |
| **Boilerplate size** | [V] Minimal (~5 lines per pref) | [V] Low (register adapter + open box) | [~] Medium — manual `CREATE TABLE`, `toMap`/`fromMap`, raw queries | [X] High — table classes, codegen setup (`build_runner`), DAO classes |
| **Testability** | [~] Needs `SharedPreferences.setMockInitialValues` | [V] Good — in-memory box via `Hive.init(tmpDir)` | [V] Good — `inMemoryDatabaseFactory` or mock the `Database` | [V] Excellent — `NativeDatabase.memory()` + generated code is directly testable |
| **1000+ notes performance** | [X] Terrible — loads entire XML into memory, linear scan | [~] OK for reads (in-memory index), but no SQL-level filtering — full scan in Dart for complex queries | [V] Excellent — B-tree indexes, SQLite query planner | [V] Excellent — same engine, same performance |
| **Sync queue support** | [X] No `dirty` flag concept | [~] Manual — add `dirty` field to model, scan all entries | [V] Native — `WHERE dirty = 1` with index | [V] Native — same, but type-safe |

Legend: `[V]` = Good/Supported, `[~]` = Partial/Limited, `[X]` = Not supported/Poor

### Schema / Box Design for 1000+ Notes

#### SharedPreferences (NOT recommended for notes)
```
// Would require serializing entire list to JSON string
key: "notes" -> value: "[{\"id\":1,\"title\":\"...\",\"dirty\":true}, ...]"
// Problems: no indexing, full deserialize on every read,
// data loss risk on concurrent writes, ~1MB practical limit
```

#### Hive Box
```dart
@HiveType(typeId: 0)
class NoteModel extends HiveObject {
  @HiveField(0) int? id;           // auto-increment manually
  @HiveField(1) String title;
  @HiveField(2) String body;
  @HiveField(3) DateTime updatedAt;
  @HiveField(4) bool dirty;
}

// Box: Hive.openBox<NoteModel>('notes')
// Query dirty: box.values.where((n) => n.dirty).toList()  <- full scan in Dart!
// No index on dirty — O(n) for 1000+ notes
```

#### sqflite (SQLite) — Current implementation
```sql
CREATE TABLE notes (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  title      TEXT    NOT NULL,
  body       TEXT    NOT NULL DEFAULT '',
  updated_at TEXT    NOT NULL,
  dirty      INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX idx_notes_dirty ON notes(dirty);
-- WHERE dirty = 1 -> index seek, O(log n) even with 100k rows
```

#### Drift
```dart
class Notes extends Table {
  IntColumn    get id        => integer().autoIncrement()();
  TextColumn   get title     => text()();
  TextColumn   get body      => text().withDefault(const Constant(''))();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn   get dirty     => boolean().withDefault(const Constant(false))();
}
// Generates: database.g.dart, companions, typed select/insert/update/delete
// Requires: build_runner, drift_dev in dev_dependencies
```

---

## 2. Final Comparison & Recommendation Table

| Need | Recommended | Runner-up | Reason |
|------|------------|-----------|--------|
| **Theme preference** (dark mode bool) | **SharedPreferences** | Hive | A single `bool` is the *exact* use-case SharedPreferences was designed for. Zero setup, 5 lines of code, platform-native. Hive is overkill — you'd open a box just for one key. |
| **Note CRUD** (1000+ notes, dirty flag, sync queue) | **sqflite (SQLite)** | Drift | Full SQL power for `WHERE dirty = 1`, indexed queries scale to 100k+ rows. Boilerplate is manageable (one `CREATE TABLE` + `toMap`/`fromMap`). Drift adds type-safety but at the cost of `build_runner` codegen complexity — not justified for a single-table app. |

### Why NOT the others for notes?

| Option | Why rejected for notes |
|--------|----------------------|
| **SharedPreferences** | Stores entire collection as one serialized blob. No indexing. No partial reads. Data corruption risk. Hard limit ~1MB. **Fragile for collections.** |
| **Hive** | Workable but suboptimal. `dirty` query is a full Dart scan (O(n)). No SQL aggregates (`COUNT`, `SUM`). No relational integrity. No `watch()` on query results (only per-key). |
| **Drift** | Technically superior (type-safe, streams, compile-time checks) but adds `build_runner` + `drift_dev` dependencies, `.g.dart` files, and learning curve. Justified for multi-table relational apps, overkill for a single `notes` table. |

---

## 3. Trade-off Summary

```
                    Simplicity <----------------------> Power
                         |                                |
   SharedPreferences *---|                                |
                         |                                |
              Hive ------*--|                             |
                            |                             |
           sqflite ---------*-----------*                 |
                                        |                 |
             Drift ---------------------*-----------------*
```

- **SharedPreferences**: Maximum simplicity, zero power. Perfect for 1-5 scalar settings.
- **Hive**: Low boilerplate NoSQL. Good for simple object storage without queries. Falls short when you need `WHERE`, `JOIN`, or indexed searches.
- **sqflite**: Best balance of power vs. simplicity for this project. Full SQL, indexes, migrations, no codegen.
- **Drift**: Maximum power + safety. Worth it for apps with 3+ related tables, complex queries, or teams that value compile-time guarantees. Overkill here.

---

## 4. AI Verification Checklist

| # | Check | Result |
|---|-------|--------|
| 1 | Did the AI place the note list in SharedPreferences? | **No** — SharedPreferences was explicitly rejected as "fragile for collections." Notes use **sqflite**. |
| 2 | Does the AI schema support a sync queue (dirty flag / updated_at) or only plain CRUD? | **Yes** — schema includes `dirty INTEGER NOT NULL DEFAULT 0` column with index `idx_notes_dirty`. `updated_at` column is also present. |
| 3 | Is the AI "real-time" claim backed by streams (Drift/watch) or just assumed? | **Honest** — the comparison notes that sqflite has **no built-in streams** (marked as partial). Only Drift provides native `watch()`. Our app uses Riverpod's `AsyncNotifier` + `invalidate()` for reactivity instead of database-level streams. |
| 4 | Is the AI boilerplate estimate realistic after you try the install (`flutter pub add` + schema migration)? | **Yes** — sqflite required `flutter pub add sqflite path` (2 packages) + one `CREATE TABLE` statement + `toMap`/`fromMap` on the model. No codegen. Drift would have required `flutter pub add drift drift_dev build_runner` + table classes + `dart run build_runner build`. |
| 5 | Final decision with reasons | **SharedPreferences for theme** (1 boolean, platform-native, minimal code) + **sqflite for notes** (SQL indexing for dirty flag, scalable to 1000+ rows, no codegen overhead). This matches the codelab's existing architecture. |

---

## 5. Final Decision

> **SharedPreferences** for theme/preferences + **sqflite (SQLite)** for notes.

This combination was chosen because:
1. **SharedPreferences** is purpose-built for scalar settings like a dark mode boolean — using anything else adds unnecessary complexity.
2. **sqflite** provides indexed SQL queries (`WHERE dirty = 1`) essential for the sync queue mechanism, scales effortlessly to 1000+ notes, and avoids the `build_runner` codegen overhead that Drift would introduce for a single-table schema.
3. The existing codebase already uses this exact combination, validating the recommendation.
