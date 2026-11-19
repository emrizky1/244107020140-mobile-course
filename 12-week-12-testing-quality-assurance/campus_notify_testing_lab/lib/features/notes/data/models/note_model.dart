import '../../domain/entities/note.dart';

class NoteModel extends Note {
  const NoteModel({
    super.id,
    required super.title,
    super.body = '',
    required super.updatedAt,
    super.dirty = false,
  });

  factory NoteModel.fromMap(Map<String, Object?> map) => NoteModel(
    id: (map['id'] as num?)?.toInt(),
    title: map['title'] as String? ?? '',
    body: map['body'] as String? ?? '',
    updatedAt:
        DateTime.tryParse(map['updated_at'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    dirty: ((map['dirty'] as num?)?.toInt() ?? 0) == 1,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'body': body,
    'updated_at': updatedAt.toIso8601String(),
    'dirty': dirty ? 1 : 0,
  };

  Note toEntity() => Note(
    id: id,
    title: title,
    body: body,
    updatedAt: updatedAt,
    dirty: dirty,
  );
}
