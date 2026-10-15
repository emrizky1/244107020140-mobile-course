import 'package:sqflite/sqflite.dart';

Future<Database> openNotesDatabase() async {
  final path = await getDatabasesPath();
  return openDatabase(
    '$path/campus_notes.db',
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
}
