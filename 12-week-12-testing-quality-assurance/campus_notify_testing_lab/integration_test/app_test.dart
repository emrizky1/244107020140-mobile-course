import 'package:campus_notify/features/notes/data/repositories/note_repository_impl.dart';
import 'package:campus_notify/features/notes/presentation/pages/notes_page.dart';
import 'package:campus_notify/features/notes/presentation/providers/notes_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';

/// Same schema as `openNotesDatabase`, but held in memory so every run starts
/// clean and never touches the real campus_notes.db file on the device.
Future<Database> _openInMemoryDatabase() => openDatabase(
  inMemoryDatabasePath,
  version: 1,
  onCreate: (db, version) => db.execute('''
    CREATE TABLE notes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      body TEXT NOT NULL DEFAULT '',
      updated_at TEXT NOT NULL,
      dirty INTEGER NOT NULL DEFAULT 0
    )
  '''),
);

/// Real composition of the notes feature (page -> notifier -> use cases ->
/// NoteRepositoryImpl -> sqflite). `main()` is not used here because it also
/// starts Firebase and asks for notification permission, which this flow does
/// not need.
Widget _buildNotesApp(Database db) => ProviderScope(
  overrides: [
    noteRepositoryProvider.overrideWithValue(
      NoteRepositoryImpl(openDb: () async => db),
    ),
  ],
  child: const MaterialApp(home: NotesPage()),
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Database db;

  setUp(() async {
    db = await _openInMemoryDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
    'a user adds a note, finds it with search and still sees it after a restart',
    (tester) async {
      await tester.pumpWidget(_buildNotesApp(db));
      await tester.pumpAndSettle();
      expect(find.text('Belum ada catatan.'), findsOneWidget);

      // Add a note through the UI.
      await tester.enterText(
        find.byKey(const Key('note-title-field')),
        'Read the material',
      );
      await tester.enterText(
        find.byKey(const Key('note-body-field')),
        'Chapter 12',
      );
      await tester.tap(find.byKey(const Key('add-note-button')));
      await tester.pumpAndSettle();

      expect(find.text('Read the material'), findsOneWidget);
      expect(find.text('Local'), findsOneWidget);
      expect(find.text('Belum ada catatan.'), findsNothing);

      // Search hides it, clearing the search brings it back.
      final searchField = find.byKey(const Key('note-search-field'));
      await tester.enterText(searchField, 'zzz-missing');
      await tester.pumpAndSettle();
      expect(find.text('Tidak ada judul catatan yang cocok.'), findsOneWidget);
      expect(find.text('Read the material'), findsNothing);

      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();
      expect(find.text('Read the material'), findsOneWidget);

      // Simulate closing and reopening the app: fresh providers, same database.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(_buildNotesApp(db));
      await tester.pumpAndSettle();

      expect(find.text('Read the material'), findsOneWidget);
      expect(find.text('Chapter 12'), findsOneWidget);
    },
  );
}
