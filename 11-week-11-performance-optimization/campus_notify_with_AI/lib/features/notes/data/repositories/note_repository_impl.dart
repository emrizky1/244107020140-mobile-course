import 'package:sqflite/sqflite.dart';

import '../../../../core/failures.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../models/note_model.dart';

class NoteRepositoryImpl implements NoteRepository {
  NoteRepositoryImpl({required this._openDb});

  final Future<Database> Function() _openDb;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    try {
      final db = await _openDb();
      final rows = await db.query('notes', orderBy: 'updated_at DESC');
      final notes = rows
          .map((row) => NoteModel.fromMap(row).toEntity())
          .toList();
      return (notes: notes, failure: null);
    } catch (_) {
      return (
        notes: const <Note>[],
        failure: const LocalFailure('Catatan gagal dimuat.'),
      );
    }
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    try {
      final db = await _openDb();
      final now = DateTime.now();
      final model = NoteModel(
        title: title,
        body: body,
        updatedAt: now,
        dirty: true,
      );
      final id = await db.insert('notes', model.toMap());
      return (
        note: Note(
          id: id,
          title: title,
          body: body,
          updatedAt: now,
          dirty: true,
        ),
        failure: null,
      );
    } catch (_) {
      return (
        note: null,
        failure: const LocalFailure('Catatan gagal disimpan.'),
      );
    }
  }
}
